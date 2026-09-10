{{ config(
    materialized    = 'table',
    schema          = 'STOCK_STAGING',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["staging", "stock_ai"]
) }}

with source_data as (
    select
        ticker,
        trade_date,
        close,
        volume,
        open,
        high,
        low,
        adj_close,
        exchange
    from {{ source('src_stock', 'prices') }}
),

renamed as (
    select
        cast(ticker as varchar) as ticker,
        cast(trade_date as date) as trade_date,
        cast(close as double) as close,
        cast(volume as bigint) as volume,
        cast(open as double) as open,
        cast(high as double) as high,
        cast(low as double) as low,
        cast(adj_close as double) as adj_close,
        cast(exchange as varchar) as exchange
    from source_data
)

select
    ticker,
    trade_date,
    close,
    volume,
    open,
    high,
    low,
    adj_close,
    exchange
from renamed
