{{ config(
    materialized    = 'table',
    schema          = 'STOCK_STAGING',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["staging", "stock_ai"]
) }}

with source_data as (
    select
        market_code,
        closed_date
    from {{ source('src_stock', 'stock_market_closed_dates') }}
),

renamed as (
    select
        market_code,
        cast(closed_date as date) as closed_date
    from source_data
)

select
    market_code,
    closed_date
from renamed
