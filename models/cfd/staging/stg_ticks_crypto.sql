{{ config(
    materialized = 'view',
    tags         = ['staging', 'cfd', 'crypto'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- stg_ticks_crypto — staging view over lake.fct_tick_crypto.
-- Crypto streams 24/7 — no overnight session like FX. The `session` field
-- is repurposed as exchange-region (GLOBAL/ASIA/LONDON/NY) and may not
-- carry the same semantics as FX session.
-- ─────────────────────────────────────────────────────────────────────────────

with raw as (
    select * from {{ source('cfd_lake', 'fct_tick_crypto') }}
),

final as (
    select
        symbol,
        ts_utc,
        bid,
        ask,
        mid,
        spread_pips,
        session       as exchange_region,
        source,
        asset_class,
        ingested_at
    from raw
)

select * from final
