{#
  One-time setup for fct_ai_chat_message pipeline.
  Creates:
    - AI_MART.PARQUET_FORMAT  (reusable Parquet file format)
    - AI_MART.EXT_CHAT_HISTORY (external table over s3://codepais3/stock/raw/chat_history/)

  Re-runnable (CREATE OR REPLACE).
  Run once per env: dbt run-operation setup_ai_chat_external
#}
{% macro setup_ai_chat_external() %}
    {% do run_query("CREATE FILE FORMAT IF NOT EXISTS AI_MART.PARQUET_FORMAT TYPE = PARQUET") %}
    {{ log("file format AI_MART.PARQUET_FORMAT ready", info=true) }}

    {% set ddl %}
        CREATE OR REPLACE EXTERNAL TABLE AI_MART.EXT_CHAT_HISTORY (
            message_id           BIGINT        AS ($1:message_id::BIGINT),
            session_id           VARCHAR       AS ($1:session_id::VARCHAR),
            session_user_id      BIGINT        AS ($1:session_user_id::BIGINT),
            ticker               VARCHAR       AS ($1:ticker::VARCHAR),
            exchange             VARCHAR       AS ($1:exchange::VARCHAR),
            session_title        VARCHAR       AS ($1:session_title::VARCHAR),
            session_created_at   TIMESTAMP_TZ  AS ($1:session_created_at::TIMESTAMP_TZ),
            role                 VARCHAR       AS ($1:role::VARCHAR),
            content              VARCHAR       AS ($1:content::VARCHAR),
            model_used           VARCHAR       AS ($1:model_used::VARCHAR),
            context_sources      VARCHAR       AS ($1:context_sources::VARCHAR),
            created_at           TIMESTAMP_TZ  AS ($1:created_at::TIMESTAMP_TZ),
            archived_at          TIMESTAMP_TZ  AS ($1:archived_at::TIMESTAMP_TZ),
            archive_run_id       VARCHAR       AS ($1:archive_run_id::VARCHAR),
            dt_year              INTEGER       AS (CAST(REGEXP_SUBSTR(METADATA$FILENAME, 'year=([0-9]+)', 1, 1, 'e', 1) AS INTEGER)),
            dt_month             INTEGER       AS (CAST(REGEXP_SUBSTR(METADATA$FILENAME, 'month=([0-9]+)', 1, 1, 'e', 1) AS INTEGER)),
            dt_day               INTEGER       AS (CAST(REGEXP_SUBSTR(METADATA$FILENAME, 'day=([0-9]+)', 1, 1, 'e', 1) AS INTEGER))
        )
        LOCATION = @DATAPAI.STOCK.S3_RAW_STAGE/chat_history/
        FILE_FORMAT = (FORMAT_NAME = 'AI_MART.PARQUET_FORMAT')
        PATTERN = '.*part-.*\\.parquet'
        AUTO_REFRESH = FALSE
    {% endset %}
    {% do run_query(ddl) %}
    {{ log("external table AI_MART.EXT_CHAT_HISTORY created", info=true) }}

    {% set refresh %}ALTER EXTERNAL TABLE AI_MART.EXT_CHAT_HISTORY REFRESH{% endset %}
    {% do run_query(refresh) %}

    {% set cnt = run_query("SELECT COUNT(*) AS n FROM AI_MART.EXT_CHAT_HISTORY") %}
    {{ log("external table rows after refresh: " ~ cnt.rows[0][0], info=true) }}
{% endmacro %}
