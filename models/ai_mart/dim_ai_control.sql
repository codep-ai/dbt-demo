{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'dim', 'control']
    )
}}

{#
  Main control dimension — 1 row per (framework_code, control_id).
  Surrogate key via dbt_utils for cross-adapter portability.
  mandatory_records kept as pipe-separated string; consumers parse per
  warehouse dialect (Snowflake SPLIT, HANA STRING_SPLIT, BigQuery SPLIT).
#}

with seed as (
    select * from {{ ref('ai_controls_seed') }}
)
select
    {{ dbt_utils.surrogate_key(['framework_code', 'control_id']) }} as control_sk,
    framework_code,
    framework_name,
    framework_publisher,
    jurisdiction_code,
    country_code,
    effective_from,
    is_mandatory,
    source_url,
    control_id,
    control_name,
    control_description,
    control_category,
    obligation_family,
    mandatory_records,
    source_section,
    retrieved_date,
    status,
    notes
from seed
