{{ config(
    materialized    = 'table',
    schema          = 'STOCK_STAGING',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["staging", "stock_ai"]
) }}

with source_data as (
    select
        exchange,
        currency_code,
        currency_symbol,
        currency_name_en,
        country
    from {{ source('src_stock', 'exchange_ref') }}
)

select
    exchange,
    currency_code,
    currency_symbol,
    currency_name_en,
    country
from source_data
