-- Guards the 2026-09-19 defect: fct_daily_price.volume was a hard-coded 0 on every row.
{{ config(tags=['stock_ai']) }}
select 'fct_daily_price.volume is zero on every row' as problem
where (select coalesce(sum(volume), 0) from {{ ref('fct_daily_price') }}) = 0
