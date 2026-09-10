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
        close,
        close_usd,
        volume,
        sma_5,
        sma_200,
        volatility_20d,
        rsi_14,
        obv,
        obv_trend,
        pivot_pp,
        kdj_k
    from {{ ref('int_price_with_indicators') }}
),

tickers as (
    select
        ticker_key,
        ticker,
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
        t.ticker_key,
        e.exchange_key,
        i.ticker,
        i.exchange,
        i.trade_date,
        i.close,
        i.close_usd,
        i.volume,
        i.sma_5,
        i.sma_200,
        i.volatility_20d,
        i.rsi_14,
        i.obv,
        i.obv_trend,
        i.pivot_pp,
        i.kdj_k
    from price_indicators i
    join tickers t
        on i.ticker = t.ticker
        and i.exchange = t.exchange
    join exchanges e
        on i.exchange = e.exchange
)

select
    ticker_key,
    exchange_key,
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
    obv_trend,
    cast(pivot_pp as double) as pivot_pp,
    cast(kdj_k as double) as kdj_k
from joined
