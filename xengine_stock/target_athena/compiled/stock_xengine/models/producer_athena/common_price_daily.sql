
-- The shared price table every consumer reads. Carries BOTH the native close and the USD close, plus the rate used,
-- so no consumer ever has to guess which currency a number is in.
--
-- INCREMENTAL MERGE ON PURPOSE (2026-09-21). A `table` model is rebuilt by DROP + CREATE on Athena, which gives the Iceberg table a
-- new UUID and folder every run. Engines that follow a table by identity (Snowflake auto-refresh, Databricks) then stop following and
-- serve the old snapshot silently. A merge keeps ONE table identity and adds snapshots, so consumers follow it with no sync step,
-- and Iceberg history / time travel survive. Each run re-merges the last 7 days (late corrections).
-- `dbt build --full-refresh` recreates the table (new UUID) — run `xengine.py snowflake-sync` afterwards.

   
with px as (
    select
        split_part(p.ticker, '.', 1) as ticker,
        upper(trim(p.exchange))      as exchange,
        p.trade_date,
        p.close,
        p.volume
    from "awsdatacatalog"."stock_iceberg"."prices" p
    -- Keep rows with a usable price. Written as an expression ON PURPOSE: a plain `close is not null` / `close > 0`
    -- is pushed down to the Parquet min/max statistics, and Athena rejects this Snowflake-written file with
    -- ICEBERG_BAD_DATA "Corrupted statistics for column close" (file stores float, Iceberg schema says double).
    where coalesce(p.close, -1) > 0
    
      and p.trade_date >= (select date_add('day', -37, max(trade_date)) from "awsdatacatalog"."stock_common"."common_price_daily")
    
),
dedup as (
    -- Raw can hold BHP.AX and BHP for the same day; conforming maps both to one key (44 rows of 8.1M on 2026-09-21).
    -- One row per key, by a fixed rule (highest volume, then highest close), because a MERGE must not see duplicate keys.
    select * from (
        select px.*, row_number() over (partition by ticker, exchange, trade_date order by volume desc nulls last, close desc) as rn
        from px
    ) where rn = 1
),
fx as (
    select trade_date, currency_code, units_per_usd from "awsdatacatalog"."stock_common"."common_fx_daily"
),
joined as (
    select
        d.ticker, d.exchange, d.trade_date, e.currency_code,
        d.close, d.volume,
        case when e.currency_code = 'USD' then 1.0 else fx.units_per_usd end as rate_on_day
    from dedup d
    join "awsdatacatalog"."stock_common"."common_exchange" e on e.exchange = d.exchange
    left join fx on fx.trade_date = d.trade_date and fx.currency_code = e.currency_code
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

where trade_date >= (select date_add('day', -7, max(trade_date)) from "awsdatacatalog"."stock_common"."common_price_daily")
