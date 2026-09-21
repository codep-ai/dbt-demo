-- Feature table built BY DATABRICKS on the tables ATHENA produced (one producer, two consumers). Columns are fully qualified on purpose:
-- lineage then resolves from the SQL alone, before the table has ever been built.
with px as (
    select
        p.ticker, p.exchange, p.trade_date, p.currency_code, p.close_usd, p.volume,
        lag(p.close_usd, 20) over (partition by p.ticker, p.exchange order by p.trade_date) as close_usd_20d_ago,
        avg(p.volume) over (partition by p.ticker, p.exchange order by p.trade_date rows between 19 preceding and current row) as avg_volume_20d
    from {{ source('stock_common_dbx', 'common_price_daily') }} p
    where p.close_usd is not null
)
select
    px.ticker,
    px.exchange,
    t.sector,
    px.trade_date,
    px.currency_code,
    px.close_usd,
    px.close_usd / nullif(px.close_usd_20d_ago, 0) - 1 as return_20d,
    px.volume / nullif(px.avg_volume_20d, 0)           as volume_vs_20d_avg
from px
left join (
    select ct.ticker, ct.exchange, max(ct.sector) as sector
    from {{ source('stock_common_dbx', 'common_ticker') }} ct
    group by ct.ticker, ct.exchange
) t on t.ticker = px.ticker and t.exchange = px.exchange
