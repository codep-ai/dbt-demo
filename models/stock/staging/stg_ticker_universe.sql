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
        exchange,
        yf_symbol,
        company_name,
        sector,
        is_active,
        asset_type,
        region
    from {{ source('src_stock', 'ticker_universe') }}
),

final as (
    select
        ticker,
        exchange,
        yf_symbol,
        company_name,
        sector,
        is_active,
        asset_type,
        region
    from source_data
)

select * from final
