{{
    config(
        materialized       = 'table',
        table_format       = 'iceberg',
        external_volume    = var('external_volume', 'DATAPAI_S3_VOL'),
        base_location_root = 'ohlcv_intraday',
        cluster_by         = ['exchange', 'ts::DATE'],
    )
}}

/*
  30-minute OHLCV intraday bars — Snowflake Managed Iceberg table.

  Source:       S3 raw Parquet at s3://$S3_BUCKET_STOCK/stock/raw/ohlcv_intraday/
  Stage:        DATAPAI.STOCK.S3_RAW_STAGE (DATAPAI_S3_INTEGRATION)
  Bronze path:  s3://$S3_BUCKET_STOCK/stock/bronze/ohlcv_intraday/STOCK/ohlcv_intraday/  (written by Snowflake)
  Data loader:  scripts/sync_snowflake_iceberg.py  ← partition-level DELETE+INSERT
  Full rebuild: dbt run --full-refresh --select ohlcv_intraday

  Note: requires dbt-snowflake>=1.9 (Python 3.9+) for Managed Iceberg table_format config.
  For daily delta loads use scripts/sync_snowflake_iceberg.py --mode delta.
*/

{% set database = env_var('SNOWFLAKE_DATABASE', 'DATAPAI') %}
{% set stage = database ~ '.STOCK.' ~ var('raw_stage', 'S3_RAW_STAGE') %}

SELECT
    $1:ticker::VARCHAR(20)    AS ticker,
    $1:ts::TIMESTAMP_NTZ(6)   AS ts,
    $1:open::DOUBLE           AS open,
    $1:high::DOUBLE           AS high,
    $1:low::DOUBLE            AS low,
    $1:close::DOUBLE          AS close,
    $1:volume::BIGINT         AS volume,
    $1:exchange::VARCHAR(10)  AS exchange,
    $1:source::VARCHAR(20)    AS source
FROM @{{ stage }}/ohlcv_intraday/
