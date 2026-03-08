{{
    config(
        materialized  = 'view',
        schema        = 'ai_mart',
        tags          = ['ai_governance', 'guardrail', 'fct', 'quality']
    )
}}

{#
  fct_ai_asset_quality
  ══════════════════════════════════════════════════════════════════════════
  Spec: claude_build_spec_v1.4  §6C
  Branch: feature/elementary-guardrail-mart

  PURPOSE
  ───────
  Operational evidence for whether an AI-governed asset is healthy enough
  for AI use at any given time.

  Source inputs:
    - dim_ai_governed_assets        — static policy + asset list
    - Elementary elementary_test_results  — test pass/fail per invocation
    - Elementary dbt_run_results          — latest model run status
    - Elementary dbt_invocations          — run timing and context

  QUALITY GATE LOGIC (§14 of spec)
  ─────────────────────────────────
    1. Critical tests fail          → should_block_ai_use = true
    2. Warnings only                → should_warn_ai_use  = true
    3. Latest run failed (error)    → should_block_ai_use = true
    4. Missing tests                → quality_gate_status = 'no_tests'
    5. Asset AI disabled or denied  → quality_gate_status = 'policy_blocked'
    6. All passing                  → quality_gate_status = 'pass'

  QUALITY SCORE
  ─────────────
    latest_quality_score is a 0–100 score:
      100 = all tests passing, run succeeded
      75  = warnings only, run succeeded
      50  = some failures OR run failed, but asset is partially usable
      0   = hard blocked (critical fail or policy deny)

  LIGHTDASH
  ─────────
  Useful for: "Assets blocked due to test failures", "Quality gate status",
  "Stale / failing assets by domain".
#}

with

-- ── 1. AI-governed asset inventory ────────────────────────────────────────
governed_assets as (

    select
        asset_key,
        asset_name,
        project_name,
        unique_id,
        ai_enabled,
        ai_access_level,
        risk_tier,
        compliance_domain,
        owner_team,
        latest_invocation_id,
        latest_run_status,
        last_run_generated_at,
        failing_tests_count,
        warning_tests_count,
        passing_tests_count,
        total_tests_count,
        latest_test_failure_names,
        last_tested_at,
        latest_test_health_status

    from {{ ref('dim_ai_governed_assets') }}

),

-- ── 2. Latest invocation metadata ─────────────────────────────────────────
latest_invocation as (

    select
        invocation_id,
        run_started_at,
        run_completed_at,
        status                      as invocation_status,
        command,
        dbt_version,
        target_name

    from {{ source('elementary', 'dbt_invocations') }}

),

-- ── 3. Run results for latest invocation per model ────────────────────────
run_results as (

    select
        unique_id,
        invocation_id,
        status                      as run_status,
        execution_time,
        rows_affected,
        generated_at

    from {{ source('elementary', 'dbt_run_results') }}

),

-- ── 4. Freshness — surface latest check per source ────────────────────────
-- Source freshness is model-level for sources; for regular models we
-- approximate from run_completed_at of the latest invocation.
freshness as (

    select
        unique_id,
        status                      as freshness_status,
        max_loaded_at,
        snapshotted_at,
        -- Staleness in seconds from snapshot to latest recorded data
        datediff(
            'second', max_loaded_at, snapshotted_at
        )                           as freshness_lag_seconds

    from {{ source('elementary', 'dbt_source_freshness_results') }}

    qualify row_number() over (
        partition by unique_id
        order by snapshotted_at desc
    ) = 1

),

-- ── 5. Combine ─────────────────────────────────────────────────────────────
combined as (

    select

        -- ── Identity ──────────────────────────────────────────────────────
        ga.asset_key,
        ga.asset_name,
        ga.project_name,
        ga.unique_id,
        ga.risk_tier,
        ga.compliance_domain,
        ga.owner_team,

        -- ── Invocation context ────────────────────────────────────────────
        coalesce(ga.latest_invocation_id, 'unknown')            as invocation_id,
        inv.run_started_at,
        inv.run_completed_at,
        coalesce(inv.invocation_status, 'unknown')              as invocation_status,
        inv.command,
        inv.target_name,

        -- ── Run quality ───────────────────────────────────────────────────
        coalesce(ga.latest_run_status, 'unknown')               as last_run_status,
        ga.last_run_generated_at                                as last_run_at,
        (ga.latest_run_status = 'error')                        as run_failed,

        -- ── Test quality ──────────────────────────────────────────────────
        ga.failing_tests_count,
        ga.warning_tests_count,
        ga.passing_tests_count,
        ga.total_tests_count,
        ga.latest_test_failure_names,
        ga.last_tested_at,
        ga.latest_test_health_status,

        -- ── Freshness (from Elementary source freshness if available) ─────
        coalesce(f.freshness_status, 'unknown')                 as freshness_status,
        f.freshness_lag_seconds,
        f.max_loaded_at,
        -- Approximate from run completion if source freshness not available
        coalesce(f.max_loaded_at, inv.run_completed_at)        as latest_data_as_of,

        -- ── Quality gate logic ────────────────────────────────────────────
        -- should_block_ai_use: any hard blocking condition
        (
            ga.ai_enabled = false
            or ga.ai_access_level = 'deny'
            or ga.latest_run_status = 'error'
            or coalesce(ga.failing_tests_count, 0) > 0
        )                                                       as should_block_ai_use,

        -- should_warn_ai_use: soft warnings
        (
            ga.ai_enabled = true
            and ga.ai_access_level != 'deny'
            and coalesce(ga.failing_tests_count, 0) = 0
            and (
                coalesce(ga.warning_tests_count, 0) > 0
                or coalesce(f.freshness_status, 'unknown') in ('warn')
                or ga.latest_run_status in ('warn', 'skip')
            )
        )                                                       as should_warn_ai_use,

        -- quality_gate_status
        case
            when ga.ai_enabled = false
              or ga.ai_access_level = 'deny'                    then 'policy_blocked'
            when ga.latest_run_status = 'error'                 then 'run_failed'
            when coalesce(ga.failing_tests_count, 0) > 0       then 'tests_failed'
            when coalesce(f.freshness_status, 'unknown') = 'error'
                                                                then 'freshness_error'
            when coalesce(ga.warning_tests_count, 0) > 0
              or coalesce(f.freshness_status, 'unknown') = 'warn'
                                                                then 'warning'
            when ga.total_tests_count = 0                       then 'no_tests'
            else 'pass'
        end                                                      as quality_gate_status,

        -- quality_gate_reason (human / AI readable)
        case
            when ga.ai_enabled = false                          then 'AI use disabled by governance policy'
            when ga.ai_access_level = 'deny'                    then 'Asset is hard-denied for all AI use'
            when ga.latest_run_status = 'error'                 then 'Latest dbt run failed — data not trustworthy'
            when coalesce(ga.failing_tests_count, 0) > 0
                then 'Data quality tests failing: ' || coalesce(ga.latest_test_failure_names, 'unknown tests')
            when coalesce(f.freshness_status, 'unknown') = 'error'
                                                                then 'Source freshness check failed — data too stale'
            when coalesce(ga.warning_tests_count, 0) > 0       then 'Test warnings present — use with caution'
            when coalesce(f.freshness_status, 'unknown') = 'warn'
                                                                then 'Freshness warning — data may be slightly stale'
            when ga.total_tests_count = 0                       then 'No dbt tests defined — quality unverified'
            else 'Quality gate passed — asset healthy for AI use'
        end                                                      as quality_gate_reason,

        -- latest_quality_score (0-100)
        case
            when ga.ai_enabled = false
              or ga.ai_access_level = 'deny'                    then 0
            when ga.latest_run_status = 'error'                 then 0
            when coalesce(ga.failing_tests_count, 0) > 0       then 25
            when coalesce(ga.warning_tests_count, 0) > 0
              or coalesce(f.freshness_status, 'unknown') = 'warn'
                                                                then 75
            when ga.total_tests_count = 0                       then 50
            else 100
        end                                                      as latest_quality_score,

        -- ── Lightdash boolean flags ───────────────────────────────────────
        (coalesce(ga.failing_tests_count, 0) > 0)               as has_failing_tests,
        (coalesce(ga.warning_tests_count, 0) > 0)               as has_test_warnings,
        (ga.total_tests_count = 0)                              as has_no_tests,
        (ga.latest_run_status = 'error')                        as run_errored,
        (coalesce(f.freshness_status, 'unknown') = 'error')     as freshness_stale,

        -- ── Snapshot ──────────────────────────────────────────────────────
        current_timestamp                                       as computed_at

    from governed_assets            ga
    left join latest_invocation     inv on ga.latest_invocation_id = inv.invocation_id
    left join freshness             f   on ga.unique_id             = f.unique_id

)

select * from combined
