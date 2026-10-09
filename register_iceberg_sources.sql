{# Register / refresh the four CFD raw-tick external Iceberg tables in
   DATAPAI.CFD_LAKE.SRC_TICK_<asset_class>. Each table is an EXTERNAL ICEBERG
   TABLE pointing at the metadata.json that Kafka Connect writes under
   s3://datapai-cfd-lake/lake/fct_tick_<class>/metadata/.

   Reads the per-class metadata file from the dbt var `cfd_iceberg_metadata`
   so the orchestrator (Cosmos / Airflow / CLI) can pass the latest snapshot
   per asset class at runtime. Defaults fall back to the last known-good
   snapshots from 2026-06-22 12:57.

   Wired into on-run-start in dbt_project.yml so `dbt run` refreshes the
   source registrations BEFORE any staging or mart model runs. No external
   Python required for the table registration — `dbt run --select cfd` does
   the entire chain: register raw → build staging → build marts → run tests.

   Run directly:
     dbt run-operation register_cfd_iceberg_sources
     dbt run-operation register_cfd_iceberg_sources \
       --args "{cfd_iceberg_metadata: {fx: 00003-xxx.metadata.json}}"
#}

{% macro register_cfd_iceberg_sources() %}

  {%- set defaults = {
      "fx":        "00002-34d1df79-6d8d-43fd-9635-093579776707.metadata.json",
      "crypto":    "00028-941b2820-36ed-4280-ad29-476c2e5a0511.metadata.json",
      "index":     "00028-a0d322a5-9417-4b84-83a5-634bb277edeb.metadata.json",
      "commodity": "00028-0e72a97f-6e9d-410c-a569-d23118cbfd6a.metadata.json"
  } -%}

  {%- set metadata_map         = var("cfd_iceberg_metadata",   defaults)     -%}
  {%- set external_volume      = var("cfd_external_volume",    "CFD_LAKE_VOL") -%}
  {%- set catalog_integration  = var("cfd_catalog_integration", "CFD_OBJ_CAT") -%}
  {%- set database             = var("cfd_database",           "DATAPAI")    -%}
  {%- set schema               = var("cfd_raw_schema",         "CFD_LAKE")   -%}

  {%- if execute -%}
    {%- do log("register_cfd_iceberg_sources: ensuring " ~ database ~ "." ~ schema, info=true) -%}
    {%- do run_query("create schema if not exists " ~ database ~ "." ~ schema) -%}

    {%- for asset_class, metadata_file in metadata_map.items() -%}
      {%- set fq            = database ~ "." ~ schema ~ ".src_tick_" ~ asset_class -%}
      {%- set metadata_path = "lake/fct_tick_" ~ asset_class ~ "/metadata/" ~ metadata_file -%}
      {%- set ddl = "create or replace iceberg table " ~ fq
                    ~ " external_volume = '" ~ external_volume      ~ "'"
                    ~ " catalog = '"         ~ catalog_integration  ~ "'"
                    ~ " metadata_file_path = '" ~ metadata_path     ~ "'" -%}
      {%- do log("  registering " ~ fq ~ " <- " ~ metadata_path, info=true) -%}
      {%- do run_query(ddl) -%}
    {%- endfor -%}

    {%- do log("register_cfd_iceberg_sources: complete", info=true) -%}
  {%- endif -%}

{% endmacro %}
