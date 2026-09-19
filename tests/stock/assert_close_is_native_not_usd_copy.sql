-- Guards the 2026-09-19 defect: fct_daily_price.close was silently a copy of close_usd.
-- For a non-USD currency whose rate is not 1, the native close and the USD close must differ.
{{ config(tags=['stock_ai']) }}
select f.ticker, f.exchange, f.trade_date, f.currency_code, f.close, f.close_usd, i.fx_rate
from {{ ref('fct_daily_price') }} f
join {{ ref('int_price_with_indicators') }} i
  on i.ticker = f.ticker and i.exchange = f.exchange and i.trade_date = f.trade_date
where f.currency_code <> 'USD'
  and f.close_usd is not null and f.close <> 0
  and abs(i.fx_rate - 1.0) > 0.0001
  and abs(f.close_usd - f.close) < 1e-9
