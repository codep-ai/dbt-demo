-- Finance-facing mart, built BY SNOWFLAKE on tables Athena produced. Small, close to the consumer.
with px as (
    select ticker, exchange, currency_code, trade_date, close, close_usd, volume
    from {{ source('stock_common', 'common_price_daily') }}
    where close_usd is not null
),
ranked as (
    select *,
           date_trunc('month', trade_date) as month_start,
           row_number() over (partition by ticker, exchange, date_trunc('month', trade_date) order by trade_date desc) as rn_last
    from px
)
select
    r.ticker,
    r.exchange,
    t.company_name,
    t.sector,
    r.currency_code,
    cast(r.month_start as date)                     as month_start,
    count(*)                                        as trading_days,
    avg(r.close_usd)                                as avg_close_usd,
    max(case when r.rn_last = 1 then r.close_usd end) as month_end_close_usd,
    max(case when r.rn_last = 1 then r.close end)     as month_end_close_native,
    sum(r.volume)                                   as total_volume
from ranked r
left join (
    select ticker, exchange, max(company_name) as company_name, max(sector) as sector
    from {{ source('stock_common', 'common_ticker') }} group by 1, 2
) t on t.ticker = r.ticker and t.exchange = r.exchange
group by 1, 2, 3, 4, 5, 6
