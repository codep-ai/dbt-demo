{#
  ai_control_snapshot
  ════════════════════════════════════════════════════════════════════════
  SCD2 snapshot of ai_controls_seed. Every content change to a seed row
  creates a new version here, preserving the old row with dbt_valid_to
  stamped.

  Enables point-in-time audit queries:
    "What did APRA CPS230.AI_OP_RISK say on 2026-01-15 when incident Y
     happened?" → SELECT * FROM ai_control_snapshot
                  WHERE framework_code = 'APRA_AI_2025'
                    AND control_id = 'CPS230.AI_OP_RISK'
                    AND dbt_valid_from <= '2026-01-15'
                    AND (dbt_valid_to > '2026-01-15' OR dbt_valid_to IS NULL)

  Strategy: `check` on the mutable attributes. Any change in the checked
  columns → new row with dbt_valid_from = now, previous row's
  dbt_valid_to stamped. Hard deletes invalidated.

  Run via: `dbt snapshot --select ai_control_snapshot`
  (Must run BEFORE `dbt run --select dim_ai_control` for fresh SCD2 state.)
#}

{% snapshot ai_control_snapshot %}

{{
    config(
      target_schema='ai_mart',
      unique_key="framework_code || '.' || control_id",
      strategy='check',
      check_cols=[
        'control_name',
        'control_description',
        'control_category',
        'obligation_family',
        'mandatory_records',
        'source_section',
        'source_url',
        'is_mandatory',
        'effective_from',
        'status',
        'notes'
      ],
      invalidate_hard_deletes=True
    )
}}

SELECT * FROM {{ ref('ai_controls_seed') }}

{% endsnapshot %}
