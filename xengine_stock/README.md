# stock_xengine — one dbt-core project, several engines, one Iceberg copy

Producer: **Athena** builds the common stock tables as Iceberg in Glue database `stock_common`.
Consumers: **Snowflake** (and later **Databricks**) read those same files and build their own marts.
Column lineage is computed per engine and stitched at the shared Iceberg tables (`datapai-platform-be/lineage/xengine`).

    export DBT_PROFILES_DIR=/home/ec2-user/.dbt
    dbt build --target athena    --select tag:producer
    dbt build --target snowflake --select tag:consumer_snowflake
