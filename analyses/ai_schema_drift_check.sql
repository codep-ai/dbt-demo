-- ══════════════════════════════════════════════════════════════════════════
-- ai_schema_drift_check.sql
-- Branch: feature/elementary-guardrail-mart  |  Spec: claude_build_spec_v1.4
-- ══════════════════════════════════════════════════════════════════════════
-- PURPOSE
-- ───────
-- Uses dbt-labs/audit_helper to detect schema drift in AI-governed models.
-- Schema drift = columns added, removed, or type-changed between runs.
-- This is a key guardrail signal: if a governed model's schema changes,
-- the AI policy catalog may be stale and must be revalidated.
--
-- AUDIT_HELPER MACROS USED
-- ────────────────────────
-- audit_helper.compare_relation_columns(a_relation, b_relation)
--   → Compares column lists between two relations (or two versions of a model)
-- audit_helper.compare_queries(a_query, b_query)
--   → Row-level comparison of two arbitrary queries
--
-- HOW TO USE
-- ──────────
-- 1. Run `dbt compile` to render these SQL blocks.
-- 2. Execute the compiled SQL in your warehouse to see schema drift reports.
-- 3. In CI: run these analyses after `dbt build` to detect column drift
--    before the policy compiler is refreshed.
-- ══════════════════════════════════════════════════════════════════════════


-- ── Section A: Governed model schema drift detection ──────────────────────
-- Compares the column list of each governed model against what the AI
-- policy catalog expects (from ai_governed_fields_seed).
-- Any extra, missing, or type-changed columns surface as drift rows.
-- ─────────────────────────────────────────────────────────────────────────

-- NOTE: audit_helper.compare_relation_columns compares two dbt relations.
-- In production: compare current relation vs previous snapshot.
-- In demo: compare seed-defined columns vs Elementary dbt_columns.


-- ── A1. Customers schema drift (example: full-jaffle-shop) ───────────────
-- Shows columns expected in AI policy but missing from the actual relation,
-- and columns present in the relation but not in the policy.
{{ audit_helper.compare_relation_columns(
    a_relation = ref('customers'),
    b_relation = ref('dim_ai_governed_fields')
) }}

/*
Expected output columns:
  in_a            boolean  — column exists in the governed model
  in_b            boolean  — column exists in the AI policy dim
  column_name     varchar  — column name
  a_data_type     varchar  — type in model (if present)
  b_data_type     varchar  — type in policy dim (if present)

Filter for drift:
  WHERE NOT (in_a AND in_b)
  → reveals columns added to the model but not yet in the policy (must review)
  → reveals columns removed from the model but still in the policy (staleness)
*/


-- ── A2. Policy catalog field count vs Elementary column count ─────────────
-- Uses audit_helper.compare_queries to compare:
--   Query A: Expected column count per model from ai_governed_fields_seed
--   Query B: Actual column count per model from Elementary dbt_columns
--
-- A mismatch signals that ai_governance.yml hasn't been updated to reflect
-- schema changes in the underlying model.

{{ audit_helper.compare_queries(
    a_query = "
        SELECT
            model_name,
            count(*) as policy_field_count
        FROM " ~ ref('dim_ai_governed_fields') ~ "
        GROUP BY 1
    ",
    b_query = "
        SELECT
            em.name       as model_name,
            count(*)      as elem_field_count
        FROM " ~ source('elementary', 'dbt_columns') ~ " dc
        JOIN " ~ source('elementary', 'dbt_models')  ~ " em
          ON dc.model_unique_id = em.unique_id
        WHERE em.name IN (
            SELECT DISTINCT model_name
            FROM " ~ ref('dim_ai_governed_fields') ~ "
        )
        GROUP BY 1
    ",
    primary_key = "model_name",
    summarize   = true
) }}

/*
Rows returned:
  model_name            — model with a mismatch
  in_a                  — appears in policy field count query
  in_b                  — appears in Elementary field count query
  a_policy_field_count  — number of columns in AI policy catalog for this model
  b_elem_field_count    — number of columns Elementary knows about

A difference means the ai_governance.yml has NOT been updated to cover all
columns in the current schema — governance coverage gap.
*/


-- ── Section B: Policy drift across invocations ────────────────────────────
-- Detects if the policy catalog hash has changed between the last two runs.
-- A change means policies have been updated and the runtime compiler cache
-- should be invalidated.
-- ─────────────────────────────────────────────────────────────────────────

{{ audit_helper.compare_queries(
    a_query = "
        SELECT
            'current'              as snapshot_label,
            " ~ ai_catalog_version_hash() ~ " as catalog_hash,
            count(*)               as asset_count,
            sum(case when ai_enabled = 'true' then 1 else 0 end) as ai_enabled_count,
            sum(case when certified_for_ai = 'true' then 1 else 0 end) as certified_count
        FROM " ~ source('ai_mart_seed', 'ai_governed_assets_seed') ~ "
    ",
    b_query = "
        SELECT
            'prior'                as snapshot_label,
            policy_catalog_version as catalog_hash,
            assets_total           as asset_count,
            ai_enabled_count,
            ai_certified_assets_count as certified_count
        FROM " ~ ref('fct_ai_policy_catalog_versions') ~ "
        LIMIT 1
    ",
    primary_key   = "snapshot_label",
    summarize     = false
) }}

/*
If catalog_hash differs between 'current' and 'prior', the policy has drifted.
Runtime compiler should invalidate its cache on next run.
*/


-- ── Section C: Missing AI governance metadata ─────────────────────────────
-- Identifies dbt models in Elementary that are NOT in the AI policy catalog.
-- These are unmanaged models — no governance decision has been made for them.
-- By default, Datap.ai denies AI use for unmanaged models (safe defaults).
-- ─────────────────────────────────────────────────────────────────────────

{{ audit_helper.compare_queries(
    a_query = "
        SELECT name as model_name, 'in_elementary' as source
        FROM " ~ source('elementary', 'dbt_models') ~ "
        WHERE package_name = 'datapai'
    ",
    b_query = "
        SELECT model_name, 'in_policy' as source
        FROM " ~ source('ai_mart_seed', 'ai_governed_assets_seed') ~ "
    ",
    primary_key = "model_name",
    summarize   = true
) }}

/*
Rows where in_a=true AND in_b=false:
  → Model exists in dbt/Elementary but has no AI governance policy.
  → Datap.ai will deny AI use by safe default.
  → Action: author meta.datapai.* in a new ai_governance.yml for these models.

Rows where in_a=false AND in_b=true:
  → Policy entry exists for a model no longer in the manifest.
  → Policy is stale / refers to a deleted model.
  → Action: remove from ai_governance.yml.
*/
