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
        open,
        high,
        low,
        close,
        volume,
        adj_close,
        exchange
    from {{ source('src_stock', 'prices') }}
),

renamed as (
    select
        ticker as ticker_raw,
        split_part(ticker, '.', 1) as ticker,
        cast(trade_date as date) as trade_date,
        cast(open as double) as open,
        cast(high as double) as high,
        cast(low as double) as low,
        cast(close as double) as close,
        cast(volume as bigint) as volume,
        cast(adj_close as double) as adj_close,
        exchange
    from source_data
),

deduplicated as (
    -- The previous version failed unique_combination_of_columns(ticker, trade_date, exchange).
    -- We apply a row_number to ensure the grain is respected as per the spec's test requirements.
    select
        *,
        row_number() over (
            partition by ticker, trade_date, exchange 
            order by ticker_raw desc
        ) as row_num
    from renamed
)

select
    ticker_raw,
    ticker,
    trade_date,
    open,
    high,
    low,
    close,
    volume,
    adj_close,
    exchange
from deduplicated
where row_num = 1
