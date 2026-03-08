{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'guardrail', 'dim']
    )
}}

{#
  dim_ai_governed_fields
  ══════════════════════════════════════════════════════════════════════════
  Spec: claude_build_spec_v1.4  §6B
  Branch: feature/elementary-guardrail-mart

  PURPOSE
  ───────
  Conformed dimension of AI-governed columns / fields with column-level
  policy and exposure settings.

  Combines:
    1. ai_governed_fields_seed  — column-level policy from ai_governance.yml
    2. ai_governed_assets_seed  — parent model policy (for asset_key join)
    3. Elementary dbt_columns   — structural type + description enrichment

  DESIGN
  ──────
  • effective_field_policy is the resolved column-level decision, taking into
    account both field-level and parent model-level signals.
  • policy_reason_summary explains the resolution for human/AI consumption.
  • Lightdash-friendly boolean flags are prefixed with `is_` or `can_`.
#}

with

-- ── 1. Seed: column-level AI governance policy ────────────────────────────
field_seed as (

    select
        model_name,
        column_name,
        ai_exposed,
        ai_selectable,
        pii_class,
        phi,
        masking_rule,
        answer_mode,
        allowed_in_output,
        allowed_in_where,
        allowed_in_group_by,
        allowed_in_retrieval,
        allowed_in_summary,
        allowed_in_export,
        business_term,
        security_class,
        notes_for_ai

    from {{ source('ai_mart_seed', 'ai_governed_fields_seed') }}

),

-- ── 2. Parent model policy (for propagation to field-level context) ───────
asset_seed as (

    select
        model_name,
        domain,
        ai_enabled,
        ai_access_level,
        default_answer_mode,
        contains_pii,
        contains_phi

    from {{ source('ai_mart_seed', 'ai_governed_assets_seed') }}

),

-- ── 3. Elementary: column structural metadata ─────────────────────────────
elem_cols as (

    select
        model_unique_id,
        name                    as column_name,
        data_type,
        description             as elem_description,
        tags,
        unique_id               as col_unique_id

    from {{ source('elementary', 'dbt_columns') }}

),

-- ── 4. Elementary: model unique_id for join bridge ───────────────────────
elem_models as (

    select name as model_name, unique_id

    from {{ source('elementary', 'dbt_models') }}

),

-- ── 5. Combine all sources ─────────────────────────────────────────────────
combined as (

    select

        -- ── Surrogate keys ────────────────────────────────────────────────
        -- field_key = <domain>.<model_name>.<column_name>
        a.domain || '.' || f.model_name || '.' || f.column_name  as field_key,
        -- asset_key matches dim_ai_governed_assets
        a.domain || '.' || f.model_name                          as asset_key,

        -- ── Structural ───────────────────────────────────────────────────
        f.model_name                                             as asset_name,
        f.column_name,
        coalesce(em.unique_id,
            'model.datapai.' || f.model_name)                    as unique_id,
        coalesce(ec.data_type, 'unknown')                        as data_type,
        coalesce(ec.elem_description, '')                        as description,

        -- ── AI governance from seed ───────────────────────────────────────
        f.ai_exposed,
        f.ai_selectable,
        -- ai_filterable / groupable / sortable derived from seed flags
        f.allowed_in_where                                       as ai_filterable,
        f.allowed_in_group_by                                    as ai_groupable,
        f.allowed_in_where                                       as ai_sortable,    -- conservative: sort allowed where filter allowed
        f.allowed_in_output,
        f.allowed_in_where,
        f.allowed_in_group_by,
        -- allowed_in_order_by: conservative — same as allowed_in_group_by
        f.allowed_in_group_by                                    as allowed_in_order_by,
        f.allowed_in_retrieval,
        f.allowed_in_summary,
        -- allowed_in_explanation: allowed if ai_exposed and not phi/direct-pii
        (
            f.ai_exposed = true
            and f.phi    = false
            and f.pii_class not in ('direct', 'indirect')
        )                                                        as allowed_in_explanation,
        f.allowed_in_export,
        f.pii_class                                              as pii,
        f.phi,
        f.security_class,
        f.masking_rule,
        f.answer_mode,
        -- join_sensitivity: if field pii or phi, flag as sensitive join key
        case
            when f.phi = true                                    then 'phi_join_risk'
            when f.pii_class in ('direct', 'indirect')          then 'pii_join_risk'
            when f.pii_class = 'quasi_identifier'               then 'quasi_join_risk'
            else 'low'
        end                                                      as join_sensitivity,
        f.allowed_in_export                                      as export_allowed,
        f.business_term,
        f.notes_for_ai,

        -- ── Parent model context ──────────────────────────────────────────
        a.ai_enabled                                             as parent_ai_enabled,
        a.ai_access_level                                        as parent_ai_access_level,
        a.default_answer_mode                                    as parent_default_answer_mode,

        -- ── Effective field policy (resolved) ─────────────────────────────
        -- Rule precedence (§8 of spec):
        --   1. parent model = deny  → field = deny
        --   2. field not exposed    → deny
        --   3. phi = true           → deny (highest sensitivity)
        --   4. pii direct/indirect  → masking required
        --   5. parent = agg-only    → field answer_mode capped at agg_only
        --   6. field answer_mode as-is
        case
            when a.ai_access_level = 'deny'                     then 'deny'
            when f.ai_exposed = false                           then 'deny'
            when f.phi = true                                   then 'deny'
            when f.pii_class in ('direct', 'indirect')
             and f.masking_rule = 'none'                        then 'deny'
            when f.pii_class in ('direct', 'indirect')         then 'masked'
            when a.default_answer_mode = 'aggregate_only'
             and f.answer_mode not in ('deny', 'aggregate_only') then 'aggregate_only'
            else f.answer_mode
        end                                                      as effective_field_policy,

        -- ── Policy reason summary ─────────────────────────────────────────
        case
            when a.ai_access_level = 'deny'                     then 'Parent model is hard-denied'
            when f.ai_exposed = false                           then 'Column not AI-exposed'
            when f.phi = true                                   then 'PHI column — hard deny'
            when f.pii_class in ('direct', 'indirect')
             and f.masking_rule = 'none'                        then 'PII without masking rule — denied'
            when f.pii_class in ('direct', 'indirect')
             and f.allowed_in_output = true                     then 'PII masked — output allowed with mask'
            when f.pii_class in ('direct', 'indirect')         then 'PII masked — output blocked'
            when a.default_answer_mode = 'aggregate_only'       then 'Capped to aggregate_only by parent model policy'
            when f.answer_mode = 'full'                         then 'Full access — column is safe for all AI use'
            else 'Policy: ' || f.answer_mode
        end                                                      as policy_reason_summary,

        -- ── Lightdash boolean flags ───────────────────────────────────────
        f.ai_exposed                                             as is_ai_exposed,
        f.ai_selectable                                          as is_ai_selectable,
        f.allowed_in_output                                      as can_appear_in_output,
        f.allowed_in_where                                       as can_use_in_filter,
        f.allowed_in_group_by                                    as can_use_in_group_by,
        f.allowed_in_retrieval                                   as can_use_in_rag,
        f.allowed_in_summary                                     as can_use_in_summary,
        f.allowed_in_export                                      as can_export,
        (f.pii_class in ('direct', 'indirect'))                  as is_pii,
        f.phi                                                    as is_phi,
        (f.masking_rule != 'none')                               as requires_masking,
        (f.answer_mode = 'deny')                                 as is_hard_deny,
        (f.answer_mode = 'aggregate_only')                       as is_aggregate_only,

        -- ── Snapshot ──────────────────────────────────────────────────────
        current_timestamp                                        as computed_at

    from field_seed         f
    join asset_seed         a   on f.model_name   = a.model_name
    left join elem_models   em  on f.model_name   = em.model_name
    left join elem_cols     ec  on em.unique_id   = ec.model_unique_id
                                and f.column_name = ec.column_name

)

select * from combined
