
-- Merge, not rebuild: keeps ONE Iceberg table identity so Snowflake / Databricks follow it with no sync (see common_price_daily.sql).
-- Reference table: every run merges the full (small) source. Rows that vanish from the source are kept, not deleted.
-- One row per exchange, with the currency its prices are quoted in.
select
    upper(trim(exchange))      as exchange,
    upper(trim(currency_code)) as currency_code,
    country
from "awsdatacatalog"."stock_iceberg"."exchange_ref"