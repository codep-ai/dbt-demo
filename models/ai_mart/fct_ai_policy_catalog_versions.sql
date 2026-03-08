{{
    config(
        materialized  = 'view',
        schema        = 'ai_mart',
        tags          = ['ai_governance', 'guardrail', 'fct', 'audit']
    )
}}

{#
  fct_ai_policy_catalog_versions
  ══════════════════════════════════════════════════════════════════════════
  Spec: claude_build_spec_v1.4  §6D
  Branch: feature/elementary-guardrail-mart

  PURPOSE
  ───────
  Snapshot / version table for the compiled AI guardrail catalog.
  Answers: "What was the AI policy catalog state as of invocation X?"

  One row per dbt invocation.  Aggregates counts from dim_ai_governed_assets
  and dim_ai_governed_fields to produce a version summary.

  Useful for:
    - Tracking policy drift over time (Lightdash: "Policy catalog changes")
    - Anchoring trace events to a specific catalog version
    - Auditing changes to the number of certified / restricted assets

  METADATA HASH
  ─────────────
  policy_catalog_version is the invocation_id (or 'seed-v1' in demo mode
  when Elementary is not connected).  In production this is an Elementary
  invocation UUID.  The runtime PolicyCompiler uses this version string
  for cache-keying.
#}

with

-- ── 1. Latest invocation context from Elementary ───────────────────────────
latest_invocation as (

    select
        invocation_id,
        run_started_at,
        run_completed_at,
        status                              as invocation_status,
        command,
        dbt_version                         as compiler_version,
        target_name,
        project_name                        as source_project

    from {{ source('elementary', 'dbt_invocations') }}

    qualify row_number() over (order by run_started_at desc) = 1

),

-- ── 2. Asset-level counts from dim_ai_governed_assets ─────────────────────
asset_counts as (

    select
        count(*)                                                as assets_total,
        count(*) filter (where ai_enabled = true)               as ai_enabled_count,
        count(*) filter (where certified_for_ai = true)         as ai_certified_assets_count,
        count(*) filter (where ai_access_level = 'deny')        as hard_deny_assets_count,
        count(*) filter (where ai_access_level = 'restricted')  as restricted_assets_count,
        count(*) filter (where ai_access_level = 'internal')    as internal_assets_count,
        count(*) filter (where ai_access_level = 'approved')    as approved_assets_count,
        count(*) filter (where default_answer_mode = 'aggregate_only')
                                                                as aggregate_only_assets_count,
        count(*) filter (where default_answer_mode = 'masked')  as masked_assets_count,
        count(*) filter (where contains_pii = true)             as pii_assets_count,
        count(*) filter (where contains_phi = true)             as phi_assets_count,
        count(distinct project_name)                            as source_projects_count,
        string_agg(distinct project_name, ', ')                 as source_projects_included

    from {{ ref('dim_ai_governed_assets') }}

),

-- ── 3. Field-level counts from dim_ai_governed_fields ─────────────────────
field_counts as (

    select
        count(*)                                                    as fields_total,
        count(*) filter (where is_ai_exposed = true)                as ai_exposed_fields_count,
        count(*) filter (where is_pii = true)                       as pii_fields_count,
        count(*) filter (where is_phi = true)                       as phi_fields_count,
        count(*) filter (where requires_masking = true)             as masked_fields_count,
        count(*) filter (where is_hard_deny = true)                 as hard_deny_fields_count,
        count(*) filter (where is_aggregate_only = true)            as aggregate_only_fields_count,
        count(*) filter (where can_appear_in_output = true)         as output_safe_fields_count,
        count(*) filter (where can_use_in_rag = true)               as rag_safe_fields_count

    from {{ ref('dim_ai_governed_fields') }}

),

-- ── 4. Quality summary ─────────────────────────────────────────────────────
quality_summary as (

    select
        count(*) filter (where quality_gate_status = 'pass')     as assets_healthy,
        count(*) filter (where should_block_ai_use = true)       as assets_blocked_by_quality,
        count(*) filter (where should_warn_ai_use  = true)       as assets_with_quality_warnings,
        count(*) filter (where quality_gate_status = 'no_tests') as assets_without_tests

    from {{ ref('fct_ai_asset_quality') }}

),

-- ── 5. Assemble version snapshot ──────────────────────────────────────────
version_snapshot as (

    select

        -- ── Catalog version identity ──────────────────────────────────────
        coalesce(
            li.invocation_id, 'seed-v1'
        )                                                       as policy_catalog_version,
        current_timestamp                                       as generated_at,
        coalesce(li.invocation_id, 'seed-v1')                  as invocation_id,
        coalesce(li.run_started_at,  current_timestamp)        as run_started_at,
        coalesce(li.run_completed_at, current_timestamp)       as run_completed_at,
        coalesce(li.invocation_status, 'demo')                 as invocation_status,
        coalesce(li.compiler_version, 'dbt-demo')              as compiler_version,
        coalesce(li.source_project, 'datapai')                 as source_project,

        -- ── Asset-level policy counts ─────────────────────────────────────
        ac.assets_total,
        ac.ai_enabled_count,
        ac.ai_certified_assets_count,
        ac.hard_deny_assets_count,
        ac.restricted_assets_count,
        ac.internal_assets_count,
        ac.approved_assets_count,
        ac.aggregate_only_assets_count,
        ac.masked_assets_count,
        ac.pii_assets_count,
        ac.phi_assets_count,
        ac.source_projects_count,
        ac.source_projects_included,

        -- ── Field-level policy counts ─────────────────────────────────────
        fc.fields_total,
        fc.ai_exposed_fields_count,
        fc.pii_fields_count,
        fc.phi_fields_count,
        fc.masked_fields_count,
        fc.hard_deny_fields_count,
        fc.aggregate_only_fields_count,
        fc.output_safe_fields_count,
        fc.rag_safe_fields_count,

        -- ── Quality summary ───────────────────────────────────────────────
        qs.assets_healthy,
        qs.assets_blocked_by_quality,
        qs.assets_with_quality_warnings,
        qs.assets_without_tests,

        -- ── Coverage metrics ──────────────────────────────────────────────
        -- Fraction of AI-enabled assets that are certified
        case
            when ac.ai_enabled_count > 0
            then round(
                100.0 * ac.ai_certified_assets_count / ac.ai_enabled_count,
                1)
            else 0
        end                                                      as pct_assets_certified,

        -- Fraction of fields that are AI-safe for output
        case
            when fc.fields_total > 0
            then round(
                100.0 * fc.output_safe_fields_count / fc.fields_total,
                1)
            else 0
        end                                                      as pct_fields_output_safe,

        -- Fraction of AI-enabled assets passing quality gate
        case
            when ac.ai_enabled_count > 0
            then round(
                100.0 * qs.assets_healthy / greatest(ac.ai_enabled_count, 1),
                1)
            else 0
        end                                                      as pct_assets_quality_healthy,

        -- ── Notes ─────────────────────────────────────────────────────────
        'Generated by fct_ai_policy_catalog_versions (v1.4 build)'
                                                                 as notes

    from asset_counts       ac
    cross join field_counts fc
    cross join quality_summary qs
    left join latest_invocation li on true   -- single row cross join

)

select * from version_snapshot
