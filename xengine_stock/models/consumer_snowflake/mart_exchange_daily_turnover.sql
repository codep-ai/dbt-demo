-- Daily turnover per exchange in USD. Built BY SNOWFLAKE from Athena-produced tables.
select
    p.exchange,
    e.country,
    p.currency_code,
    p.trade_date,
    count(distinct p.ticker)        as tickers_traded,
    sum(p.close_usd * p.volume)     as turnover_usd,
    sum(p.volume)                   as total_volume
from {{ source('stock_common', 'common_price_daily') }} p
join {{ source('stock_common', 'common_exchange') }} e on e.exchange = p.exchange
where p.close_usd is not null
group by 1, 2, 3, 4
