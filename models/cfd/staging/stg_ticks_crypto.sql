{{ config(
    materialized = 'view',
    tags         = ['staging', 'cfd', 'crypto'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- stg_ticks_crypto — staging view over CFD_LAKE.fct_tick_crypto, the SF-registered
-- Iceberg table that points at the Kafka-Connect-written metadata.json in
-- s3://datapai-cfd-lake/lake/fct_tick_crypto/. Casts TS_UTC (VARCHAR in the
-- raw Iceberg) to TIMESTAMP_NTZ and emits a synthetic ingested_at from
-- current_timestamp at view materialization (no native ingest timestamp
-- in the Kafka Connect Iceberg sink output).
-- ─────────────────────────────────────────────────────────────────────────────

with raw as (
    select * from {{ source('cfd_lake', 'src_tick_crypto') }}
),

final as (
    select
        symbol,
        cast(try_to_timestamp_ntz(ts_utc) as timestamp_ntz(6)) as ts_utc,
        bid,
        ask,
        mid,
        spread_pips,
    session       as exchange_region,
        source,
    asset_class,
        cast(current_timestamp() as timestamp_ntz(6)) as ingested_at
    from raw
)

select * from final
