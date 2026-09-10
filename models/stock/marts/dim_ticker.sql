{{ config(
    materialized    = 'table',
    schema          = 'STOCK_MARTS',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["dimension", "stock_ai"]
) }}

with ticker_source as (
    select
        yf_symbol,
        ticker_local,
        exchange,
        company_name,
        sector,
        is_active,
        asset_type
    from {{ ref('stg_ticker_universe') }}
),

final as (
    select
        md5(concat_ws('|', coalesce(cast(yf_symbol as varchar), ''), coalesce(cast(exchange as varchar), ''))) as ticker_key,
        yf_symbol,
        ticker_local,
        exchange,
        company_name,
        sector,
        is_active,
        asset_type
    from ticker_source
)

select * from final
