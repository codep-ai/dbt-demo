{{ config(
    materialized = 'view',
    tags         = ['staging', 'cfd', 'index'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- stg_ticks_index — staging view over lake.fct_tick_index. Indices include
-- SPX500, US30 (Dow), NAS100, UK100 (FTSE 100), GER40 (DAX).
-- ─────────────────────────────────────────────────────────────────────────────

with raw as (
    select * from {{ source('cfd_lake', 'fct_tick_index') }}
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
