-- Conformed ticker: sources disagree on the symbol (BHP.AX vs BHP). One business key, the raw symbol kept for audit.
select
    split_part(ticker, '.', 1)  as ticker,
    ticker                      as ticker_raw,
    upper(trim(exchange))       as exchange,
    company_name,
    sector,
    asset_type,
    region,
    is_active
from {{ source('stock_raw', 'ticker_universe') }}
