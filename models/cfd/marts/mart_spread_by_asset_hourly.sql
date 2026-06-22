{{ config(
    materialized = 'table',
    tags         = ['marts', 'cfd', 'ai_consumed'],
) }}

-- ─────────────────────────────────────────────────────────────────────────────
-- mart_spread_by_asset_hourly — average bid-ask spread per (asset_class,
-- symbol, hour). Powers the Spread Quality dashboard in Lightdash and the
-- spread-vs-best-execution governance check.
-- ─────────────────────────────────────────────────────────────────────────────

with src as (
    select * from {{ ref('fct_tick_unified') }}
),

hourly as (
    select
        asset_class,
        symbol,
        cast(date_trunc('hour', ts_utc) as timestamp_ntz(6)) as event_hour,
        count(*)                          as ticks,
        round(avg(spread_pips)::numeric, 3) as avg_spread_pips,
        round(min(spread_pips)::numeric, 3) as min_spread_pips,
        round(max(spread_pips)::numeric, 3) as max_spread_pips,
        round(avg(mid)::numeric, 5)         as avg_mid
    from src
    group by asset_class, symbol, date_trunc('hour', ts_utc)
)

select * from hourly
