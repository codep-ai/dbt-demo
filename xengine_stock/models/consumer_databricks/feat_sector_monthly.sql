-- Built BY DATABRICKS on a mart SNOWFLAKE produced: the Snowflake -> Databricks crossing (Snowflake-generated Iceberg, read from S3).
select
    m.sector,
    m.month_start,
    count(distinct m.ticker)      as tickers,
    avg(m.avg_close_usd)          as sector_avg_close_usd,
    sum(m.total_volume)           as sector_total_volume
from {{ source('stock_consumer_sf', 'mart_price_monthly_usd') }} m
where m.sector is not null
group by m.sector, m.month_start
