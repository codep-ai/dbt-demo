-- Guards the 2026-09-19 defect: USD-quoted rows had a NULL close_usd wherever FX history was missing.
-- A USD price needs no conversion: close_usd must exist and equal close.
{{ config(tags=['stock_ai']) }}
select ticker, exchange, trade_date, close, close_usd
from {{ ref('fct_daily_price') }}
where currency_code = 'USD'
  and close is not null
  and (close_usd is null or abs(close_usd - close) > 1e-9)
