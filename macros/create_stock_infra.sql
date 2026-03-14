{% macro create_stock_infra() %}
  {#
    One-time infrastructure setup for the DATAPAI.STOCK Iceberg pipeline.

    Creates (all idempotent via IF NOT EXISTS):
      1. DATAPAI.STOCK schema
      2. DATAPAI_S3_INTEGRATION  (requires ACCOUNTADMIN)
      3. DATAPAI_S3_VOL           (requires ACCOUNTADMIN)
      4. DATAPAI.STOCK.S3_RAW_STAGE

    After running:
      1. Run: DESCRIBE INTEGRATION DATAPAI_S3_INTEGRATION;
      2. Copy STORAGE_AWS_IAM_USER_ARN + STORAGE_AWS_EXTERNAL_ID
      3. Update the IAM trust policy on the role in AWS console.

    Required env vars:
      SNOWFLAKE_DATABASE     (default: DATAPAI)
      SNOWFLAKE_S3_ROLE_ARN  IAM role ARN for Snowflake → S3 access
      S3_BUCKET_STOCK        S3 bucket (default: codepais3)
      AWS_DEFAULT_REGION     (default: ap-southeast-2)

    Run with (from repo root):
      export SNOWFLAKE_ROLE=ACCOUNTADMIN
      dbt --profiles-dir dbt/ run-operation create_stock_infra
  #}

  {% set database    = env_var('SNOWFLAKE_DATABASE',    'DATAPAI') %}
  {% set s3_bucket   = env_var('S3_BUCKET_STOCK',       'codepais3') %}
  {% set aws_region  = env_var('AWS_DEFAULT_REGION',    'ap-southeast-2') %}
  {% set role_arn    = env_var('SNOWFLAKE_S3_ROLE_ARN', '') %}
  {% set schema      = 'STOCK' %}
  {% set integration = 'DATAPAI_S3_INTEGRATION' %}
  {% set ext_volume  = 'DATAPAI_S3_VOL' %}
  {% set s3_raw_url    = 's3://' ~ s3_bucket ~ '/stock/raw/' %}
  {% set s3_bronze_url = 's3://' ~ s3_bucket ~ '/stock/bronze/' %}

  {% if not role_arn %}
    {{ exceptions.raise_compiler_error(
        "SNOWFLAKE_S3_ROLE_ARN env var is required. "
        "Set it to the IAM role ARN that Snowflake uses to access S3."
    ) }}
  {% endif %}

  -- ── 1. Schema ────────────────────────────────────────────────────────────
  {% set sql_schema %}
    CREATE SCHEMA IF NOT EXISTS {{ database }}.{{ schema }};
  {% endset %}
  {% do run_query(sql_schema) %}
  {% do log("✓ Schema " ~ database ~ "." ~ schema ~ " ready", info=True) %}

  -- ── 2. Storage Integration (ACCOUNTADMIN required) ───────────────────────
  {% set sql_integration %}
    CREATE STORAGE INTEGRATION IF NOT EXISTS {{ integration }}
      TYPE                      = EXTERNAL_STAGE
      STORAGE_PROVIDER          = 'S3'
      ENABLED                   = TRUE
      STORAGE_AWS_ROLE_ARN      = '{{ role_arn }}'
      STORAGE_ALLOWED_LOCATIONS = ('s3://{{ s3_bucket }}/stock/');
  {% endset %}
  {% do run_query(sql_integration) %}
  {% do log("✓ Storage integration " ~ integration ~ " ready", info=True) %}

  -- ── 3. External Volume (ACCOUNTADMIN required) ───────────────────────────
  {% set sql_volume %}
    CREATE EXTERNAL VOLUME IF NOT EXISTS {{ ext_volume }}
      STORAGE_LOCATIONS = (
        (
          NAME             = 'datapai-{{ aws_region }}'
          STORAGE_PROVIDER = 'S3'
          STORAGE_BASE_URL = '{{ s3_bronze_url }}'
          STORAGE_AWS_ROLE_ARN = '{{ role_arn }}'
        )
      );
  {% endset %}
  {% do run_query(sql_volume) %}
  {% do log("✓ External volume " ~ ext_volume ~ " ready", info=True) %}

  -- ── 4. S3 Stage for raw Parquet ──────────────────────────────────────────
  {% set sql_stage %}
    CREATE STAGE IF NOT EXISTS {{ database }}.{{ schema }}.S3_RAW_STAGE
      URL                = '{{ s3_raw_url }}'
      STORAGE_INTEGRATION = {{ integration }}
      FILE_FORMAT        = (TYPE = PARQUET SNAPPY_COMPRESSION = TRUE);
  {% endset %}
  {% do run_query(sql_stage) %}
  {% do log("✓ Stage " ~ database ~ "." ~ schema ~ ".S3_RAW_STAGE ready", info=True) %}

  {% do log("", info=True) %}
  {% do log("Infrastructure setup complete.", info=True) %}
  {% do log("Next steps:", info=True) %}
  {% do log("  1. Run: DESCRIBE INTEGRATION " ~ integration ~ ";", info=True) %}
  {% do log("  2. Copy STORAGE_AWS_IAM_USER_ARN + STORAGE_AWS_EXTERNAL_ID", info=True) %}
  {% do log("  3. Update IAM trust policy for role " ~ role_arn ~ " in AWS console.", info=True) %}
  {% do log("  4. Run: dbt --profiles-dir dbt/ run --full-refresh", info=True) %}

{% endmacro %}
