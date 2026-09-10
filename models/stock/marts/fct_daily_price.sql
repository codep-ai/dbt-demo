{{ config(
    materialized    = 'table',
    schema          = 'STOCK_MARTS',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["fact", "stock_ai"]
) }}

with price_indicators as (
    select
        ticker,
        exchange,
        trade_date,
        close_usd,
        sma_5,
        rsi_14,
        macd_line,
        obv_trend,
        volatility_20d,
        pivot_pp
    from {{ ref('int_price_with_indicators') }}
),

tickers as (
    select
        ticker_key,
        yf_symbol,
        exchange
    from {{ ref('dim_ticker') }}
),

exchanges as (
    select
        exchange_key,
        exchange
    from {{ ref('dim_exchange') }}
),

joined as (
    select
        md5(concat_ws('|', coalesce(cast(i.ticker as varchar), ''), coalesce(cast(i.exchange as varchar), ''), coalesce(cast(i.trade_date as varchar), ''))) as daily_price_key,
        t.ticker_key,
        e.exchange_key,
        i.ticker,
        i.exchange,
        i.trade_date,
        i.close_usd as close,
        i.close_usd,
        cast(0 as double) as volume
    from price_indicators i
    left join tickers t
        on i.ticker = t.yf_symbol
        and i.exchange = t.exchange
    left join exchanges e
        on i.exchange = e.exchange
)

select
    daily_price_key,
    ticker_key,
    exchange_key,
    ticker,
    exchange,
    trade_date,
    close,
    close_usd,
    volume
from joined
