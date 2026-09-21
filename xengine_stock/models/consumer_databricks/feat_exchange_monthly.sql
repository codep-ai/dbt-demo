-- Built BY DATABRICKS on a mart SNOWFLAKE produced: the Snowflake -> Databricks crossing.
-- Grouped by exchange and currency (both populated). The first version grouped by `sector`, which is NULL for every row of the raw
-- ticker table, so it built an EMPTY table that still passed its not-null tests (2026-09-21). Hence the not-empty test below.
select
    m.exchange,
    m.currency_code,
    m.month_start,
    count(distinct m.ticker)      as tickers,
    avg(m.avg_close_usd)          as avg_close_usd,
    sum(m.total_volume)           as total_volume
from {{ source('stock_consumer_sf', 'mart_price_monthly_usd') }} m
group by m.exchange, m.currency_code, m.month_start
