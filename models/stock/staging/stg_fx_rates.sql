{{ config(
    materialized    = 'table',
    schema          = 'STOCK_STAGING',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["staging", "stock_ai"]
) }}

with source_data as (
    select
        base_currency,
        quote_currency,
        rate,
        try_to_date(trade_date) as trade_date
    from {{ source('src_stock', 'fx_rates_daily') }}
),

final as (
    select
        base_currency,
        quote_currency,
        rate,
        trade_date
    from source_data
)

select * from final
