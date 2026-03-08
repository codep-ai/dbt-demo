{{
    config(
        materialized  = 'view',
        schema        = 'ai_mart',
        tags          = ['ai_governance', 'guardrail', 'fct', 'eligibility']
    )
}}

{#
  fct_ai_asset_runtime_eligibility
  ══════════════════════════════════════════════════════════════════════════
  Spec: claude_build_spec_v1.4  §6E
  Branch: feature/elementary-guardrail-mart

  PURPOSE
  ───────
  Precomputed runtime eligibility combining:
    - Static governance policy     (dim_ai_governed_assets)
    - Operational quality signals  (fct_ai_asset_quality)
    - Per-AI-use-case rules        (cross join on use case values)

  This is the PRIMARY mart consumed by the Datap.ai runtime policy
  compiler (WarehousePolicyCompiler) to decide:
    - Can this asset be used for this AI use case right now?
    - What answer mode applies?
    - Is masking required?
    - Is approval required?
    - What is the reason for the decision?

  STRUCTURE
  ─────────
  One row per (asset × AI use case).
  AI use cases match AiUseCase enum in guardrail/governed_action.py:
    text2sql | rag_retrieval | summarization | export | explanation
    bi_metric_explanation | field_explanation | dbt_model_explanation
    document_extraction | tool_action | airbyte_trigger | narrative_insight
    semantic_search | data_profiling | model_comparison | dashboard_explanation

  ELIGIBILITY LOGIC (§8 of spec — 9-rule precedence)
  ───────────────────────────────────────────────────
    1. hard deny by governance metadata        → BLOCKED
    2. hard deny by restricted PII/PHI rules   → BLOCKED (PHI cols present)
    3. block by failing quality gate           → BLOCKED (if critical fail)
    4. aggregate-only enforcement              → ELIGIBLE with aggregate_only
    5. masked-only enforcement                 → ELIGIBLE with masked
    6. metadata-only enforcement               → ELIGIBLE with metadata_only
    7. approval-required enforcement           → ELIGIBLE with approval flag
    8. restricted workspace                    → ELIGIBLE (with restriction note)
    9. allow if all conditions pass            → ELIGIBLE full

  LIGHTDASH
  ─────────
  Useful for: "Runtime eligibility by use case", "Blocked assets by domain",
  "Use cases approved vs blocked per model".
#}

with

-- ── 1. AI use cases (universe) ────────────────────────────────────────────
-- Matches AiUseCase enum in governed_action.py
use_cases as (

    select use_case from (values
        ('text2sql'),
        ('rag_retrieval'),
        ('summarization'),
        ('export'),
        ('explanation'),
        ('bi_metric_explanation'),
        ('field_explanation'),
        ('dbt_model_explanation'),
        ('document_extraction'),
        ('tool_action'),
        ('airbyte_trigger'),
        ('narrative_insight'),
        ('semantic_search'),
        ('data_profiling'),
        ('model_comparison'),
        ('dashboard_explanation')
    ) as t(use_case)

),

-- ── 2. Governed assets (policy + operational quality) ─────────────────────
assets as (

    select
        ga.asset_key,
        ga.asset_name,
        ga.project_name,
        ga.unique_id,
        ga.risk_tier,
        ga.compliance_domain,
        ga.ai_enabled,
        ga.ai_access_level,
        ga.certified_for_ai,
        ga.contains_pii,
        ga.contains_phi,
        ga.default_answer_mode,
        ga.retrieval_policy,
        ga.summarization_policy,
        ga.explanation_policy,
        ga.rag_exposure,
        ga.export_policy,
        ga.agent_action_policy,
        ga.latest_invocation_id,
        ga.eligibility_status,
        -- Quality signals from fct_ai_asset_quality
        aq.quality_gate_status,
        aq.should_block_ai_use,
        aq.should_warn_ai_use,
        aq.latest_quality_score,
        aq.quality_gate_reason,
        aq.freshness_status,
        aq.has_failing_tests,
        aq.has_test_warnings,
        aq.has_no_tests

    from {{ ref('dim_ai_governed_assets') }}   ga
    left join {{ ref('fct_ai_asset_quality') }} aq  on ga.asset_key = aq.asset_key

),

-- ── 3. Cross-join assets × use cases, then resolve eligibility ───────────
eligibility as (

    select

        -- ── Identity ──────────────────────────────────────────────────────
        a.asset_key,
        a.asset_name,
        a.project_name,
        a.unique_id,
        uc.use_case                                              as ai_use_case,
        a.risk_tier,
        a.compliance_domain,

        -- ── Quality signals ───────────────────────────────────────────────
        coalesce(a.quality_gate_status, 'unknown')              as latest_quality_gate_status,
        coalesce(a.latest_quality_score, 0)                     as latest_quality_score,
        a.latest_invocation_id                                  as last_invocation_id,
        coalesce(a.freshness_status, 'unknown')                 as freshness_status,

        -- ── Policy catalog version ────────────────────────────────────────
        -- Joins fct_ai_policy_catalog_versions for version string
        (select policy_catalog_version
         from {{ ref('fct_ai_policy_catalog_versions') }}
         limit 1)                                               as policy_catalog_version,

        -- ── Per-use-case policy flags ─────────────────────────────────────
        -- These map use_case to the relevant policy field from the asset dim.
        case uc.use_case
            when 'rag_retrieval'          then a.retrieval_policy
            when 'summarization'          then a.summarization_policy
            when 'explanation'            then a.explanation_policy
            when 'bi_metric_explanation'  then a.explanation_policy
            when 'field_explanation'      then a.explanation_policy
            when 'dbt_model_explanation'  then a.explanation_policy
            when 'dashboard_explanation'  then a.explanation_policy
            when 'export'                 then a.export_policy
            when 'tool_action'            then a.agent_action_policy
            when 'airbyte_trigger'        then a.agent_action_policy
            -- For text2sql / narrative / semantic / profiling / comparison:
            -- derive from default answer mode + ai_access_level
            else case
                when a.ai_access_level = 'approved'             then 'allow'
                when a.ai_access_level = 'internal'             then 'limited'
                when a.ai_access_level = 'restricted'           then 'deny'
                else 'deny'
            end
        end                                                      as use_case_policy,

        -- ── Runtime block flag (hard blocking conditions) ─────────────────
        (
            a.ai_enabled = false
            or a.ai_access_level = 'deny'
            or a.contains_phi = true                             -- PHI model always blocked
            or coalesce(a.should_block_ai_use, false) = true    -- quality gate failed
        )                                                        as runtime_block_flag,

        -- ── Runtime warning flag ──────────────────────────────────────────
        coalesce(a.should_warn_ai_use, false)                    as runtime_warning_flag,

        -- ── Masking required ──────────────────────────────────────────────
        (
            a.contains_pii = true
            or a.default_answer_mode in ('masked')
        )                                                        as runtime_masking_required,

        -- ── Approval required ─────────────────────────────────────────────
        (
            a.ai_access_level = 'restricted'
            or uc.use_case = 'export'
            or uc.use_case = 'airbyte_trigger'
        )                                                        as runtime_approval_required,

        -- ── Runtime answer mode ───────────────────────────────────────────
        -- Derived from policy + quality signals
        case
            -- Hard blocks first
            when a.ai_enabled = false                           then 'deny'
            when a.ai_access_level = 'deny'                     then 'deny'
            when a.contains_phi = true                          then 'deny'
            when coalesce(a.should_block_ai_use, false) = true  then 'deny'
            -- Use-case specific deny
            when case uc.use_case
                    when 'rag_retrieval'         then a.retrieval_policy
                    when 'summarization'         then a.summarization_policy
                    when 'export'                then a.export_policy
                    when 'tool_action'           then a.agent_action_policy
                    when 'airbyte_trigger'       then a.agent_action_policy
                    else 'allow'
                 end = 'deny'                                   then 'deny'
            -- Quality degradation
            when coalesce(a.should_warn_ai_use, false) = true
             and a.default_answer_mode = 'full'                 then 'metadata_only'
            -- PHI/PII masking
            when a.contains_pii = true
             and a.default_answer_mode not in ('aggregate_only', 'deny')
                                                                then 'masked'
            -- Aggregate-only
            when a.default_answer_mode = 'aggregate_only'       then 'aggregate_only'
            -- Masked-only
            when a.default_answer_mode = 'masked'               then 'masked'
            -- Metadata-only
            when a.default_answer_mode = 'metadata_only'        then 'metadata_only'
            -- RAG-specific
            when uc.use_case = 'rag_retrieval'
             and a.rag_exposure = 'metadata_only'               then 'metadata_only'
            -- Full access
            else 'full'
        end                                                      as runtime_answer_mode,

        -- ── Runtime eligibility status ────────────────────────────────────
        case
            when a.ai_enabled = false                           then 'blocked'
            when a.ai_access_level = 'deny'                     then 'blocked'
            when a.contains_phi = true                          then 'blocked'
            when coalesce(a.should_block_ai_use, false) = true  then 'blocked'
            when case uc.use_case
                    when 'rag_retrieval'   then a.retrieval_policy
                    when 'summarization'   then a.summarization_policy
                    when 'export'          then a.export_policy
                    when 'tool_action'     then a.agent_action_policy
                    when 'airbyte_trigger' then a.agent_action_policy
                    else 'allow'
                 end = 'deny'                                   then 'blocked'
            when coalesce(a.should_warn_ai_use, false) = true  then 'eligible_with_warning'
            when a.ai_access_level = 'restricted'               then 'eligible_restricted'
            when a.ai_access_level = 'internal'                 then 'eligible_internal'
            when a.certified_for_ai = true                      then 'eligible_certified'
            else 'eligible'
        end                                                      as runtime_eligibility_status,

        -- ── Runtime reason summary ────────────────────────────────────────
        case
            when a.ai_enabled = false
                then 'AI use disabled by governance policy'
            when a.ai_access_level = 'deny'
                then 'Asset hard-denied by governance metadata'
            when a.contains_phi = true
                then 'Asset contains PHI — hard deny for all AI use cases'
            when coalesce(a.should_block_ai_use, false) = true
                then coalesce(a.quality_gate_reason, 'Quality gate failed')
            when case uc.use_case
                    when 'rag_retrieval'   then a.retrieval_policy
                    when 'summarization'   then a.summarization_policy
                    when 'export'          then a.export_policy
                    when 'tool_action'     then a.agent_action_policy
                    when 'airbyte_trigger' then a.agent_action_policy
                    else 'allow'
                 end = 'deny'
                then 'Use case "' || uc.use_case || '" denied by asset policy'
            when coalesce(a.should_warn_ai_use, false) = true
                then 'Eligible with warning: ' || coalesce(a.quality_gate_reason, 'quality signal degraded')
            when a.ai_access_level = 'restricted'
                then 'Eligible but restricted — workspace/tenant approval may be required'
            when a.certified_for_ai = true
                then 'Certified AI-eligible asset — use case "' || uc.use_case || '" approved'
            else 'Approved for "' || uc.use_case || '" use'
        end                                                      as runtime_reason_summary,

        -- ── Lightdash boolean flags ───────────────────────────────────────
        not (
            a.ai_enabled = false
            or a.ai_access_level = 'deny'
            or a.contains_phi = true
            or coalesce(a.should_block_ai_use, false) = true
        )                                                        as is_eligible,
        (a.ai_enabled = false or a.ai_access_level = 'deny')    as is_policy_blocked,
        coalesce(a.should_block_ai_use, false)                   as is_quality_blocked,
        coalesce(a.should_warn_ai_use, false)                    as has_quality_warning,
        a.certified_for_ai                                       as is_certified,
        (a.ai_access_level = 'restricted')                       as is_restricted,

        -- ── Snapshot ──────────────────────────────────────────────────────
        current_timestamp                                        as computed_at

    from assets     a
    cross join use_cases uc

)

select * from eligibility
