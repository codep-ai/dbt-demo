-- One row per exchange, with the currency its prices are quoted in.
select
    upper(trim(exchange))      as exchange,
    upper(trim(currency_code)) as currency_code,
    country
from {{ source('stock_raw', 'exchange_ref') }}
