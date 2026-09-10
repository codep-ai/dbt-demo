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
        try_to_date(trade_date) as trade_date,
        cast(rate as number(38, 10)) as rate
    from {{ source('src_stock', 'fx_rates_daily') }}
    where base_currency = 'USD'
),

final as (
    select
        md5(concat_ws('|', coalesce(cast(quote_currency as varchar), ''), coalesce(cast(trade_date as varchar), ''))) as fx_rate_id,
        base_currency,
        quote_currency,
        cast(trade_date as timestamp_ntz(6)) as trade_date,
        rate
    from source_data
)

select
    fx_rate_id,
    base_currency,
    quote_currency,
    trade_date,
    rate
from final
