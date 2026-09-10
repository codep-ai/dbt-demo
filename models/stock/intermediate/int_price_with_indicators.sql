{{ config(
    materialized    = 'table',
    schema          = 'STOCK_INTERMEDIATE',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["intermediate", "stock_ai"]
) }}

with base_prices as (
    select
        p.ticker,
        p.exchange,
        p.trade_date,
        p.close,
        p.volume,
        p.high,
        p.low,
        e.currency_code
    from {{ ref('stg_prices') }} p
    join {{ ref('stg_exchange_ref') }} e
        on p.exchange = e.exchange
),

fx_rates as (
    select
        quote_currency,
        trade_date,
        rate
    from {{ ref('stg_fx_rates') }}
),

joined_data as (
    select
        b.*,
        fx.rate as raw_rate,
        last_value(fx.rate) ignore nulls over (
            partition by b.currency_code 
            order by b.trade_date 
            rows between unbounded preceding and current row
        ) as filled_rate
    from base_prices b
    left join fx_rates fx
        on b.currency_code = fx.quote_currency
        and b.trade_date = fx.trade_date
),

normalized_prices as (
    select
        ticker,
        exchange,
        trade_date,
        close,
        volume,
        high,
        low,
        close / coalesce(raw_rate, filled_rate) as close_usd,
        lag(close) over (partition by ticker, exchange order by trade_date) as prev_close,
        lag(high) over (partition by ticker, exchange order by trade_date) as prev_high,
        lag(low) over (partition by ticker, exchange order by trade_date) as prev_low
    from joined_data
),

indicators_step_1 as (
    select
        *,
        avg(close) over (partition by ticker, exchange order by trade_date rows between 4 preceding and current row) as sma_5,
        avg(close) over (partition by ticker, exchange order by trade_date rows between 199 preceding and current row) as sma_200,
        /* Fix: Ensure ln() argument is > 0. If close/prev_close <= 0, ln is undefined. */
        stddev(ln(nullif(case when close > 0 and prev_close > 0 then close / prev_close else null end, 0))) 
            over (partition by ticker, exchange order by trade_date rows between 19 preceding and current row) * sqrt(252) * 100 as volatility_20d,
        avg(case when close > prev_close then close - prev_close else 0 end) 
            over (partition by ticker, exchange order by trade_date rows between 13 preceding and current row) as rsi_gain,
        avg(case when close < prev_close then prev_close - close else 0 end) 
            over (partition by ticker, exchange order by trade_date rows between 13 preceding and current row) as rsi_loss,
        sum(case 
            when close > prev_close then volume 
            when close < prev_close then -volume 
            else 0 
        end) over (partition by ticker, exchange order by trade_date rows between unbounded preceding and current row) as obv,
        (prev_high + prev_low + prev_close) / 3 as pivot_pp,
        (close - min(low) over (partition by ticker, exchange order by trade_date rows between 8 preceding and current row)) / 
            nullif(max(high) over (partition by ticker, exchange order by trade_date rows between 8 preceding and current row) - 
                   min(low) over (partition by ticker, exchange order by trade_date rows between 8 preceding and current row), 0) * 100 as raw_k
    from normalized_prices
),

final_indicators as (
    select
        *,
        100 - (100 / (1 + (rsi_gain / nullif(rsi_loss, 0)))) as rsi_14,
        case 
            when (obv - lag(obv, 10) over (partition by ticker, exchange order by trade_date)) > 0 then 'UP' 
            when (obv - lag(obv, 10) over (partition by ticker, exchange order by trade_date)) < 0 then 'DOWN' 
            else 'FLAT' 
        end as obv_trend,
        avg(raw_k) over (partition by ticker, exchange order by trade_date rows between 2 preceding and current row) as kdj_k
    from indicators_step_1
)

select
    ticker,
    exchange,
    trade_date,
    cast(close as double) as close,
    cast(close_usd as double) as close_usd,
    cast(volume as bigint) as volume,
    cast(sma_5 as double) as sma_5,
    cast(sma_200 as double) as sma_200,
    cast(volatility_20d as double) as volatility_20d,
    cast(rsi_14 as double) as rsi_14,
    cast(obv as bigint) as obv,
    cast(obv_trend as varchar) as obv_trend,
    cast(pivot_pp as double) as pivot_pp,
    cast(kdj_k as double) as kdj_k
from final_indicators
