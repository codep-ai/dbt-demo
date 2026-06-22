{{ config(
    materialized = 'view',
    tags         = ['staging', 'cfd', 'commodity'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- stg_ticks_commodity — staging view over lake.fct_tick_commodity. Commodities
-- here cover oil (WTI, BRENT) and natural gas. Gold (XAUUSD) lives in the FX
-- topic by industry convention.
-- ─────────────────────────────────────────────────────────────────────────────

with raw as (
    select * from {{ source('cfd_lake', 'fct_tick_commodity') }}
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
