{{ config(
    materialized    = 'table',
    schema          = 'STOCK_MARTS',
    table_format    = 'iceberg',
    external_volume = 'DATAPAI_S3_VOL',
    tags            = ["dimension", "stock_ai"]
) }}

with recursive date_range as (
    select 
        min(trade_date) as min_date,
        max(trade_date) as max_date
    from {{ ref('stg_prices') }}
),

date_spine as (
    select min_date as date_day
    from date_range
    union all
    select dateadd(day, 1, date_day)
    from date_spine
    join date_range on date_spine.date_day < date_range.max_date
),

exchanges as (
    select distinct exchange
    from {{ ref('stg_prices') }}
),

base_grid as (
    select 
        d.date_day,
        e.exchange
    from date_spine d
    cross join exchanges e
),

closed_dates as (
    select 
        exchange,
        closed_date
    from {{ ref('stg_closed_dates') }}
),

final as (
    select
        b.date_day,
        b.exchange,
        case 
            when dayname(b.date_day) in ('Sat', 'Sun') then false
            when c.closed_date is not null then false
            else true
        end as is_trading_day
    from base_grid b
    left join closed_dates c 
        on b.date_day = c.closed_date 
        and b.exchange = c.exchange
)

select
    cast(date_day as date) as date_day,
    cast(exchange as varchar) as exchange,
    cast(is_trading_day as boolean) as is_trading_day
from final
