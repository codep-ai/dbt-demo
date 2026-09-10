{{ config(
    materialized    = 'table',
    schema          = 'STOCK_MARTS',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["dimension", "stock_ai"]
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
    from {{ ref('stg_ticker_universe') }}
),

final as (
    select
        md5(concat_ws('|', coalesce(cast(ticker as varchar), ''), coalesce(cast(exchange as varchar), ''))) as ticker_key,
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
