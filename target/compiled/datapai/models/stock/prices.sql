

/*
  Daily OHLCV prices — Snowflake permanent table (CTAS from S3 raw stage).

  Source:       S3 raw Parquet at s3://$S3_BUCKET_STOCK/stock/raw/prices/
  Stage:        DATAPAI.STOCK.S3_RAW_STAGE (DATAPAI_S3_INTEGRATION)
  Data loader:  scripts/sync_s3_to_snowflake.py  ← partition-level DELETE+INSERT
  Full rebuild: dbt run --full-refresh --select prices

  Schema managed by dbt.  Data loaded by sync_s3_to_snowflake.py.
  For daily delta loads use scripts/sync_s3_to_snowflake.py --mode delta.
*/




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
FROM @DATAPAI.STOCK.S3_RAW_STAGE/prices/