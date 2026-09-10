{{ config(
    materialized    = 'table',
    schema          = 'STOCK_STAGING',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["staging", "stock_ai"]
) }}

with source_data as (
    select
        yf_symbol,
        ticker as ticker_local,
        exchange,
        company_name,
        sector,
        is_active,
        asset_type
    from {{ source('src_stock', 'ticker_universe') }}
),

final as (
    select
        cast(yf_symbol as varchar) as yf_symbol,
        cast(ticker_local as varchar) as ticker_local,
        cast(exchange as varchar) as exchange,
        cast(company_name as varchar) as company_name,
        cast(sector as varchar) as sector,
        cast(is_active as boolean) as is_active,
        cast(asset_type as varchar) as asset_type
    from source_data
)

select * from final
