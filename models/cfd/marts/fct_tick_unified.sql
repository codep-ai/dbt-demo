{{ config(
    materialized = 'table',
    tags         = ['marts', 'cfd', 'ai_consumed', 'ai_governance'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- fct_tick_unified — single fact table over all four asset classes (fx,
-- crypto, index, commodity). Lets the AI Trade Council, BI dashboards,
-- and downstream marts query "what was the market doing at time T?"
-- without a UNION ALL in every query.
-- ─────────────────────────────────────────────────────────────────────────────

with fx as (
    select * from {{ ref('stg_ticks_fx') }}
),
crypto as (
    select
        symbol, ts_utc, bid, ask, mid, spread_pips,
        exchange_region as session,   -- normalize column name
        source, asset_class, ingested_at
    from {{ ref('stg_ticks_crypto') }}
),
idx as (
    select * from {{ ref('stg_ticks_index') }}
),
commodity as (
    select * from {{ ref('stg_ticks_commodity') }}
),

unioned as (
    select * from fx
    union all
    select * from crypto
    union all
    select * from idx
    union all
    select * from commodity
),

final as (
    select
        asset_class,
        symbol,
        ts_utc,
        bid,
        ask,
        mid,
        spread_pips,
        session,
        source,
        ingested_at
    from unioned
)

select * from final
