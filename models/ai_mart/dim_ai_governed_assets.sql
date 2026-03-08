{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'guardrail', 'dim']
    )
}}

{#
  dim_ai_governed_assets
  ══════════════════════════════════════════════════════════════════════════
  Spec: claude_build_spec_v1.4  §6A
  Branch: feature/elementary-guardrail-mart

  PURPOSE
  ───────
  Conformed dimension of AI-governed dbt assets (models and sources).
  Combines:
    1. Static policy catalog  — from ai_governed_assets_seed (compiled from
       ai_governance.yml files).  This is the authoritative governance layer.
    2. Elementary evidence     — joins dbt_models + dbt_run_results +
       dbt_invocations to surface operational signals (latest run status,
       invocation, and freshness status).

  The seed provides structured, pre-parsed governance metadata without
  requiring JSON parsing of Elementary's VARIANT meta column.
  The Elementary join adds runtime evidence: last run, test health, freshness.

  DESIGN
  ──────
  • In demo mode (seeds only) the Elementary JOIN columns gracefully null.
  • In production (Elementary wired) the join enriches each row with
    the latest invocation and run-quality snapshot.
  • eligibility_status is derived here for Lightdash dashboards; the full
    runtime decision is in fct_ai_asset_runtime_eligibility.

  LIGHTDASH
  ─────────
  Dimensions: asset_key, project_name, asset_name, ai_access_level, ...
  Booleans:   is_ai_enabled, is_certified, is_pii, is_phi, ...
  Metrics:    (from fct_ai_asset_runtime_eligibility)
#}

with

-- ── 1. Seed: static AI governance policy ──────────────────────────────────
policy_seed as (

    select
        model_name,
        domain,
        ai_enabled,
        certified_for_ai,
        ai_access_level,
        sensitivity_level,
        contains_pii,
        contains_phi,
        default_answer_mode,
        risk_tier,
        compliance_domain,
        owner_team,
        business_owner,
        steward,
        retrieval_policy,
        summarization_policy,
        explanation_policy,
        rag_exposure,
        export_policy,
        agent_action_policy,
        safe_description

    from {{ source('ai_mart_seed', 'ai_governed_assets_seed') }}

),

-- ── 2. Elementary: model-level structural metadata ────────────────────────
-- Outer-joined so the model works when Elementary tables are empty / absent.
elem_models as (

    select
        name                    as model_name,
        unique_id,
        schema_name,
        database_name,
        package_name,
        original_path,
        materialization,
        description             as elem_description,
        tags

    from {{ source('elementary', 'dbt_models') }}

),

-- ── 3. Elementary: latest invocation per model (from run results) ─────────
-- Selects the most-recent invocation_id and run status per model.
latest_run as (

    select
        unique_id,
        invocation_id           as latest_invocation_id,
        status                  as latest_run_status,
        generated_at            as last_run_generated_at,
        row_number() over (
            partition by unique_id
            order by generated_at desc
        )                       as rn

    from {{ source('elementary', 'dbt_run_results') }}

),

latest_run_dedup as (

    select * from latest_run
    where rn = 1

),

-- ── 4. Elementary: test health summary per model ──────────────────────────
-- Counts pass / fail / warn across all tests for the latest invocation.
test_summary as (

    select
        model_unique_id,
        invocation_id,
        count(*) filter (where status = 'fail')          as failing_tests_count,
        count(*) filter (where status = 'warn')          as warning_tests_count,
        count(*) filter (where status = 'pass')          as passing_tests_count,
        count(*)                                         as total_tests_count,
        max(detected_at)                                 as last_tested_at,
        -- Collect names of failing tests as a comma-separated string
        string_agg(
            case when status = 'fail' then test_sub_type else null end,
            ', '
        )                                               as latest_test_failure_names

    from {{ source('elementary', 'elementary_test_results') }}

    -- Only look at the most-recent invocation per model
    where (model_unique_id, invocation_id) in (
        select unique_id, latest_invocation_id
        from latest_run_dedup
    )

    group by model_unique_id, invocation_id

),

-- ── 5. Join: combine seed + Elementary ────────────────────────────────────
combined as (

    select

        -- ── Surrogate keys ────────────────────────────────────────────────
        -- asset_key = <domain>.<model_name>  (stable, human-readable)
        p.domain || '.' || p.model_name                  as asset_key,
        'model'                                          as resource_type,
        p.model_name                                     as asset_name,
        p.domain                                         as project_name,

        -- ── Elementary structural fields ──────────────────────────────────
        coalesce(em.unique_id,
            'model.datapai.' || p.model_name)            as unique_id,
        em.schema_name,
        em.database_name,
        em.package_name,
        em.original_path                                 as model_path,
        em.materialization,
        em.tags,

        -- ── Static AI governance policy (from seed) ───────────────────────
        p.ai_enabled,
        p.certified_for_ai,
        p.ai_access_level,
        p.sensitivity_level,
        p.contains_pii,
        p.contains_phi,
        p.default_answer_mode,
        p.risk_tier,
        p.compliance_domain,
        p.owner_team,
        p.business_owner,
        p.steward,
        p.retrieval_policy,
        p.summarization_policy,
        p.explanation_policy,
        p.rag_exposure,
        p.export_policy,
        p.agent_action_policy,
        p.safe_description,

        -- ── Elementary operational signals ────────────────────────────────
        lr.latest_invocation_id,
        lr.latest_run_status,
        lr.last_run_generated_at,

        -- ── Test health signals ───────────────────────────────────────────
        coalesce(ts.failing_tests_count, 0)             as failing_tests_count,
        coalesce(ts.warning_tests_count, 0)             as warning_tests_count,
        coalesce(ts.passing_tests_count, 0)             as passing_tests_count,
        coalesce(ts.total_tests_count,  0)              as total_tests_count,
        ts.last_tested_at,
        ts.latest_test_failure_names,

        -- ── Derived: test health status ───────────────────────────────────
        case
            when coalesce(ts.total_tests_count, 0) = 0  then 'no_tests'
            when coalesce(ts.failing_tests_count, 0) > 0 then 'failing'
            when coalesce(ts.warning_tests_count, 0) > 0 then 'warning'
            else 'passing'
        end                                             as latest_test_health_status,

        -- ── Derived: freshness status (placeholder — wired in quality fact) ─
        -- Full freshness logic is in fct_ai_asset_quality.
        'unknown'                                       as latest_freshness_status,

        -- ── Derived: eligibility_status (high-level, for Lightdash) ─────
        case
            when p.ai_enabled = false
              or p.ai_access_level = 'deny'              then 'blocked'
            when lr.latest_run_status in ('error')       then 'blocked_run_failed'
            when coalesce(ts.failing_tests_count, 0) > 0 then 'blocked_tests_failed'
            when p.ai_access_level = 'restricted'        then 'restricted'
            when p.ai_access_level = 'internal'          then 'internal'
            when p.certified_for_ai = true
             and p.ai_access_level  = 'approved'         then 'certified'
            else 'approved'
        end                                             as eligibility_status,

        -- ── Derived: eligibility_reason_summary ──────────────────────────
        case
            when p.ai_enabled = false                   then 'AI disabled by policy'
            when p.ai_access_level = 'deny'             then 'Hard deny by governance metadata'
            when lr.latest_run_status in ('error')      then 'Latest dbt run failed'
            when coalesce(ts.failing_tests_count, 0) > 0
                then 'Failing tests: ' || coalesce(ts.latest_test_failure_names, 'unknown')
            when p.ai_access_level = 'restricted'       then 'Restricted — limited workspace access only'
            when p.ai_access_level = 'internal'         then 'Internal — available within approved teams'
            when p.certified_for_ai = true              then 'Certified AI-eligible asset'
            else 'Approved for AI use'
        end                                             as eligibility_reason_summary,

        -- ── Lightdash-friendly boolean flags ─────────────────────────────
        p.ai_enabled                                    as is_ai_enabled,
        p.certified_for_ai                              as is_certified_for_ai,
        p.contains_pii                                  as is_pii_model,
        p.contains_phi                                  as is_phi_model,
        (p.default_answer_mode = 'aggregate_only')      as is_aggregate_only,
        (p.default_answer_mode = 'masked')              as is_masked_only,
        (p.default_answer_mode = 'deny')                as is_hard_deny,
        (p.ai_access_level in ('deny'))                 as is_blocked_by_policy,
        (coalesce(ts.failing_tests_count, 0) > 0)       as has_failing_tests,
        (lr.latest_run_status = 'error')                as latest_run_failed,

        -- ── Snapshot timestamp ────────────────────────────────────────────
        current_timestamp                               as computed_at

    from policy_seed            p
    left join elem_models       em  on p.model_name = em.model_name
    left join latest_run_dedup  lr  on em.unique_id  = lr.unique_id
    left join test_summary      ts  on em.unique_id  = ts.model_unique_id

)

select * from combined
