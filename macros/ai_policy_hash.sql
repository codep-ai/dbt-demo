{#
  ai_policy_hash
  ══════════════════════════════════════════════════════════════════════════
  Branch: feature/elementary-guardrail-mart  |  Spec: claude_build_spec_v1.4

  Macros for computing stable version hashes over the AI policy catalog.
  Used by fct_ai_policy_catalog_versions and the WarehousePolicyCompiler.

  These hashes are used to:
    - Detect policy drift between dbt runs
    - Cache-invalidate the runtime policy compiler
    - Anchor trace events to a specific catalog snapshot
#}


{# ─────────────────────────────────────────────────────────────────────────
   ai_policy_hash_asset(model_name, ai_access_level, default_answer_mode,
                        contains_pii, contains_phi, risk_tier)
   ──────────────────────────────────────────────────────────────────────────
   Returns an MD5 hash string representing the core policy fields of a
   single governed asset.  Useful for change detection at the asset level.
#}
{% macro ai_policy_hash_asset(
    model_name,
    ai_access_level,
    default_answer_mode,
    contains_pii,
    contains_phi,
    risk_tier
) %}

    {{ dbt_utils.generate_surrogate_key([
        model_name,
        ai_access_level,
        default_answer_mode,
        contains_pii | string,
        contains_phi  | string,
        risk_tier
    ]) }}

{% endmacro %}


{# ─────────────────────────────────────────────────────────────────────────
   ai_policy_hash_field(model_name, column_name, pii_class, masking_rule,
                        answer_mode, allowed_in_output)
   ──────────────────────────────────────────────────────────────────────────
   Returns an MD5 hash string for a single column-level policy.
#}
{% macro ai_policy_hash_field(
    model_name,
    column_name,
    pii_class,
    masking_rule,
    answer_mode,
    allowed_in_output
) %}

    {{ dbt_utils.generate_surrogate_key([
        model_name,
        column_name,
        pii_class,
        masking_rule,
        answer_mode,
        allowed_in_output | string
    ]) }}

{% endmacro %}


{# ─────────────────────────────────────────────────────────────────────────
   ai_catalog_version_hash()
   ──────────────────────────────────────────────────────────────────────────
   Returns a SQL expression that computes an MD5 hash over the full content
   of the ai_governed_assets_seed.  When this hash changes between runs,
   the policy catalog has drifted.

   Usage in a model:
     select {{ ai_catalog_version_hash() }} as catalog_hash
     from {{ source('ai_mart_seed', 'ai_governed_assets_seed') }}
#}
{% macro ai_catalog_version_hash() %}

    md5(
        string_agg(
            model_name
            || '|' || coalesce(ai_access_level,     'null')
            || '|' || coalesce(sensitivity_level,   'null')
            || '|' || coalesce(default_answer_mode, 'null')
            || '|' || coalesce(risk_tier,           'null')
            || '|' || coalesce(contains_pii::varchar,'null')
            || '|' || coalesce(contains_phi::varchar,'null'),
            '||'
            order by model_name
        )
    )

{% endmacro %}


{# ─────────────────────────────────────────────────────────────────────────
   ai_quality_gate_status(failing_tests_count, warning_tests_count,
                          run_status, freshness_status, ai_enabled,
                          ai_access_level)
   ──────────────────────────────────────────────────────────────────────────
   Reusable macro that emits the canonical quality gate CASE expression.
   Keeps quality gate logic DRY across mart models.

   Usage:
     {{ ai_quality_gate_status(
         'tr.failing_tests_count',
         'tr.warning_tests_count',
         'rr.status',
         'f.freshness_status',
         'ga.ai_enabled',
         'ga.ai_access_level'
     ) }}  as quality_gate_status
#}
{% macro ai_quality_gate_status(
    failing_col,
    warning_col,
    run_status_col,
    freshness_col,
    ai_enabled_col,
    ai_access_col
) %}

    case
        when {{ ai_enabled_col }} = false
          or {{ ai_access_col }}  = 'deny'                then 'policy_blocked'
        when {{ run_status_col }} = 'error'               then 'run_failed'
        when coalesce({{ failing_col }}, 0) > 0           then 'tests_failed'
        when coalesce({{ freshness_col }}, 'unknown')
             = 'error'                                    then 'freshness_error'
        when coalesce({{ warning_col }}, 0) > 0
          or coalesce({{ freshness_col }}, 'unknown')
             = 'warn'                                     then 'warning'
        else 'pass'
    end

{% endmacro %}


{# ─────────────────────────────────────────────────────────────────────────
   ai_effective_answer_mode(ai_enabled, ai_access_level, contains_pii,
                            contains_phi, default_answer_mode,
                            should_block, should_warn)
   ──────────────────────────────────────────────────────────────────────────
   Reusable macro for computing effective runtime answer mode.
   Implements the 9-rule precedence from §8 of the spec.
#}
{% macro ai_effective_answer_mode(
    ai_enabled_col,
    ai_access_col,
    contains_pii_col,
    contains_phi_col,
    default_mode_col,
    should_block_col,
    should_warn_col
) %}

    case
        when {{ ai_enabled_col }}   = false               then 'deny'
        when {{ ai_access_col }}    = 'deny'              then 'deny'
        when {{ contains_phi_col }} = true                then 'deny'
        when coalesce({{ should_block_col }}, false)      then 'deny'
        when coalesce({{ should_warn_col }}, false)
         and {{ default_mode_col }} = 'full'              then 'metadata_only'
        when {{ contains_pii_col }} = true
         and {{ default_mode_col }} not in ('aggregate_only','deny')
                                                          then 'masked'
        else {{ default_mode_col }}
    end

{% endmacro %}
