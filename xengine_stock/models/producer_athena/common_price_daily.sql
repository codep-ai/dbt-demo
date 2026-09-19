-- The shared price table every consumer reads. Carries BOTH the native close and the USD close, plus the rate used,
-- so no consumer ever has to guess which currency a number is in.
with px as (
    select
        split_part(p.ticker, '.', 1) as ticker,
        upper(trim(p.exchange))      as exchange,
        p.trade_date,
        p.close,
        p.volume
    from {{ source('stock_raw', 'prices') }} p
    -- Keep rows with a usable price. Written as an expression ON PURPOSE: a plain `close is not null` / `close > 0`
    -- is pushed down to the Parquet min/max statistics, and Athena rejects this Snowflake-written file with
    -- ICEBERG_BAD_DATA "Corrupted statistics for column close" (file stores float, Iceberg schema says double).
    -- Reading values is fine; only stats-based pruning on that column fails. See the 2026-09-19 journal.
    where coalesce(p.close, -1) > 0
),
fx as (
    select trade_date, currency_code, units_per_usd from {{ ref('common_fx_daily') }}
),
joined as (
    select
        px.ticker, px.exchange, px.trade_date, e.currency_code,
        px.close, px.volume,
        case when e.currency_code = 'USD' then 1.0 else fx.units_per_usd end as rate_on_day
    from px
    join {{ ref('common_exchange') }} e on e.exchange = px.exchange
    left join fx on fx.trade_date = px.trade_date and fx.currency_code = e.currency_code
),
filled as (
    -- markets trade on days FX does not publish: carry the last known rate forward, per currency
    select *,
        coalesce(rate_on_day,
                 last_value(rate_on_day) ignore nulls over (
                     partition by currency_code order by trade_date
                     rows between unbounded preceding and current row)) as units_per_usd
    from joined
)
select
    ticker, exchange, trade_date, currency_code,
    close,
    units_per_usd,
    close / units_per_usd as close_usd,
    cast(volume as double) as volume
from filled
