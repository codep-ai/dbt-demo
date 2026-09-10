{{ config(
    materialized    = 'table',
    schema          = 'STOCK_MARTS',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["dimension", "stock_ai"]
) }}

with date_range as (
    select 
        min(trade_date) as start_date,
        max(trade_date) as end_date
    from {{ ref('stg_prices') }}
),

spine as (
    select 
        dateadd(day, seq4(), start_date) as date_day
    from date_range, 
    table(generator(rowcount => 10000))
    where dateadd(day, seq4(), start_date) <= (select end_date from date_range)
),

exchanges as (
    select distinct 
        exchange 
    from {{ ref('stg_prices') }}
),

calendar_base as (
    select 
        s.date_day,
        e.exchange
    from spine s
    cross join exchanges e
),

joined as (
    select 
        cb.date_day,
        cb.exchange,
        case 
            when c.closed_date is null 
                 and dayname(cb.date_day) not in ('Sat', 'Sun') 
            then true 
            else false 
        end as is_trading_day
    from calendar_base cb
    left join {{ ref('stg_closed_dates') }} c 
        on cb.date_day = c.closed_date 
        and cb.exchange = c.market_code
)

select 
    date_day,
    exchange,
    is_trading_day
from joined
