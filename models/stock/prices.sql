{{
    config(
        materialized       = 'table',
        table_format       = 'iceberg',
        external_volume    = var('external_volume', 'DATAPAI_S3_VOL'),
        base_location_root = 'prices',
        cluster_by         = ['exchange', 'trade_date'],
    )
}}

/*
  Daily OHLCV prices — Snowflake Managed Iceberg table.

  Source:       S3 raw Parquet at s3://$S3_BUCKET_STOCK/stock/raw/prices/
  Stage:        DATAPAI.STOCK.S3_RAW_STAGE (DATAPAI_S3_INTEGRATION)
  Bronze path:  s3://$S3_BUCKET_STOCK/stock/bronze/prices/STOCK/prices/  (written by Snowflake)
  Data loader:  scripts/sync_snowflake_iceberg.py  ← partition-level DELETE+INSERT
  Full rebuild: dbt run --full-refresh --select prices

  Schema managed by dbt.  Data loaded by sync_snowflake_iceberg.py.

  Note: requires dbt-snowflake>=1.9 (Python 3.9+) for Managed Iceberg table_format config.
  For daily delta loads use scripts/sync_snowflake_iceberg.py --mode delta.
*/

{% set database = env_var('SNOWFLAKE_DATABASE', 'DATAPAI') %}
{% set stage = database ~ '.STOCK.' ~ var('raw_stage', 'S3_RAW_STAGE') %}

SELECT
    $1:ticker::VARCHAR(20)    AS ticker,
    $1:trade_date::DATE       AS trade_date,
    $1:open::DOUBLE           AS open,
    $1:high::DOUBLE           AS high,
    $1:low::DOUBLE            AS low,
    $1:close::DOUBLE          AS close,
    $1:adj_close::DOUBLE      AS adj_close,
    $1:volume::BIGINT         AS volume,
    $1:exchange::VARCHAR(10)  AS exchange,
    $1:source::VARCHAR(20)    AS source
FROM @{{ stage }}/prices/
