{{ config(
    materialized    = 'table',
    schema          = 'STOCK_INTERMEDIATE',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["intermediate", "stock_ai"]
) }}

with prices as (
    select
        ticker,
        exchange,
        trade_date,
        open,
        high,
        low,
        close,
        volume,
        lag(close) over (partition by ticker, exchange order by trade_date) as prev_close,
        close - lag(close) over (partition by ticker, exchange order by trade_date) as price_change
    from {{ ref('stg_prices') }}
),

fx_rates as (
    select
        quote_currency,
        cast(trade_date as date) as trade_date,
        rate
    from {{ ref('stg_fx_rates') }}
),

exchanges as (
    select
        exchange,
        currency_code
    from {{ ref('stg_exchange_ref') }}
),

joined as (
    select
        p.*,
        e.currency_code,
        last_value(fx.rate) ignore nulls over (partition by e.currency_code order by p.trade_date rows between unbounded preceding and current row) as effective_fx_rate
    from prices p
    left join exchanges e
        on p.exchange = e.exchange
    left join fx_rates fx
        on e.currency_code = fx.quote_currency
        and p.trade_date = fx.trade_date
),

indicators as (
    select
        *,
        close / nullif(effective_fx_rate, 0) as close_usd,
        avg(close) over (partition by ticker, exchange order by trade_date rows between 4 preceding and current row) as sma_5,
        -- Fix: Ensure ln() argument is strictly positive to avoid 'Invalid floating point operation'
        stddev(ln(nullif(case when close > 0 and prev_close > 0 then close / prev_close end, 0))) over (partition by ticker, exchange order by trade_date rows between 19 preceding and current row) * sqrt(252) * 100 as volatility_20d,
        avg(case when price_change > 0 then price_change end) over (partition by ticker, exchange order by trade_date rows between 13 preceding and current row) as avg_gain_14,
        avg(case when price_change < 0 then abs(price_change) end) over (partition by ticker, exchange order by trade_date rows between 13 preceding and current row) as avg_loss_14,
        sum(case 
            when close > prev_close then volume 
            when close < prev_close then -volume 
            else 0 
        end) over (partition by ticker, exchange order by trade_date rows between unbounded preceding and current row) as obv,
        (lag(high) over (partition by ticker, exchange order by trade_date) + 
         lag(low) over (partition by ticker, exchange order by trade_date) + 
         lag(close) over (partition by ticker, exchange order by trade_date)) / 3 as pivot_pp,
        avg(close) over (partition by ticker, exchange order by trade_date rows between 11 preceding and current row) - 
        avg(close) over (partition by ticker, exchange order by trade_date rows between 25 preceding and current row) as macd_line
    from joined
),

final_metrics as (
    select
        *,
        100 - (100 / (1 + nullif(avg_gain_14 / nullif(avg_loss_14, 0), 0))) as rsi_14,
        case 
            when (obv - lag(obv, 10) over (partition by ticker, exchange order by trade_date)) > 0 then 'UP'
            when (obv - lag(obv, 10) over (partition by ticker, exchange order by trade_date)) < 0 then 'DOWN'
            else 'FLAT'
        end as obv_trend
    from indicators
)

select
    cast(ticker as varchar) as ticker,
    cast(exchange as varchar) as exchange,
    cast(trade_date as timestamp_ntz(6)) as trade_date,
    cast(close_usd as double) as close_usd,
    cast(sma_5 as double) as sma_5,
    cast(rsi_14 as double) as rsi_14,
    cast(macd_line as double) as macd_line,
    cast(obv_trend as varchar) as obv_trend,
    cast(volatility_20d as double) as volatility_20d,
    cast(pivot_pp as double) as pivot_pp
from final_metrics
