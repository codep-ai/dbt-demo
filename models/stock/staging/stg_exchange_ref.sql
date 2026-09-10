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
        country
    from {{ source('src_stock', 'exchange_ref') }}
),

final as (
    select
        cast(exchange as varchar) as exchange,
        cast(currency_code as varchar) as currency_code,
        cast(country as varchar) as country
    from source_data
)

select
    exchange,
    currency_code,
    country
from final
