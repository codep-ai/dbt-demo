{{ config(
    materialized = 'view',
    tags         = ['staging', 'cfd', 'fx'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- stg_ticks_fx — staging view over the Iceberg lake table written by Kafka
-- Connect (lake.fct_tick_fx). Source of truth: s3://datapai-cfd-lake/lake/
-- fct_tick_fx/ — Apache Iceberg + Parquet. Read via the Iceberg REST catalog.
-- ─────────────────────────────────────────────────────────────────────────────

with raw as (
    select * from {{ source('cfd_lake', 'fct_tick_fx') }}
),

final as (
    select
        symbol,
        ts_utc,
        bid,
        ask,
        mid,
        spread_pips,
        session,
        source,
        asset_class,
        ingested_at
    from raw
)

select * from final
