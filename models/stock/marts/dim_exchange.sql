{{ config(
    materialized    = 'table',
    schema          = 'STOCK_MARTS',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["dimension", "stock_ai"]
) }}

with source_data as (
    select
        exchange,
        currency_code,
        currency_symbol,
        currency_name_en,
        country
    from {{ ref('stg_exchange_ref') }}
),

final as (
    select
        md5(concat_ws('|', coalesce(cast(exchange as varchar), ''))) as exchange_key,
        exchange,
        currency_code,
        currency_symbol,
        currency_name_en,
        country
    from source_data
)

select * from final
