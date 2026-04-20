{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'dim', 'control']
    )
}}

{#
  dim_ai_control — conformed control dim with SCD2 + self-referencing hierarchy.
  ══════════════════════════════════════════════════════════════════════════

  SOURCE — ai_control_snapshot
  ────────────────────────────
  SCD2 snapshot of ai_controls_seed. Each row carries dbt_valid_from and
  dbt_valid_to; when a seed row's content changes the snapshot records a
  new version. Enables point-in-time audit queries:

    -- "What did ASIC.AGENTIC_AI say on 2026-02-15 (when incident Y happened)?"
    SELECT * FROM dim_ai_control
    WHERE framework_code = 'ASIC_AI_2024' AND control_id = 'ASIC.AGENTIC_AI'
      AND valid_from <= '2026-02-15'
      AND (valid_to > '2026-02-15' OR valid_to IS NULL);

  HIERARCHY (self-referencing, derived from dot-notation)
  ───────────────────────────────────────────────────────
  Control IDs follow dot-notation (e.g. GOVERN-1.2 has parent GOVERN-1,
  CPS230.AI_OP_RISK has parent CPS230). Enables tree queries:

    parent_control_id   → string id of parent or NULL if top-level
    parent_control_sk   → surrogate FK to the parent row (NULL if no parent exists)
    root_control_id     → top-of-tree id (everything under GOVERN-1 shares root=GOVERN-1)
    hierarchy_level     → 1 (top), 2 (first sub), 3 (second sub), ...
    is_leaf             → TRUE if no other row declares this as parent

  COMPLIANCE ASSESSOR USE
  ───────────────────────
  Assess only leaf controls (is_leaf = TRUE) — parent/rollup rows are
  summaries, not independently evaluable. Filter when feeding controls
  to the LLM.

  Run order: dbt snapshot --select ai_control_snapshot  BEFORE  dbt run --select dim_ai_control.
#}

with snap as (
    select * from {{ ref('ai_control_snapshot') }}
),

-- Derive parent_id + root + level from dot-notation per row
hier as (
    select
        snap.*,
        case when position('.' in control_id) > 0
             then split_part(control_id, '.', 1)
             else null
        end                                                                  as parent_control_id_computed,
        split_part(control_id, '.', 1)                                       as root_control_id_computed,
        length(control_id) - length(replace(control_id, '.', '')) + 1        as hierarchy_level_computed
    from snap
),

-- Distinct (framework, parent) pairs — used to determine is_leaf
parent_refs as (
    select distinct framework_code, parent_control_id_computed
    from hier
    where parent_control_id_computed is not null
)

select
    -- SCD2 surrogate key includes dbt_valid_from so each version is uniquely keyed
    {{ dbt_utils.surrogate_key(['h.framework_code', 'h.control_id', 'h.dbt_valid_from']) }}             as control_sk,
    -- Natural key (version-agnostic) for current-version joins
    h.framework_code || '.' || h.control_id                                                             as control_nk,

    -- Framework-level attrs
    h.framework_code,
    h.framework_name,
    h.framework_publisher,
    h.jurisdiction_code,
    h.jurisdiction_scope,
    h.country_code,
    h.effective_from,
    h.is_mandatory,
    h.source_url,

    -- Control-level attrs
    h.control_id,
    h.control_name,
    h.control_description,
    h.control_category,
    h.obligation_family,
    h.mandatory_records,
    h.source_section,
    h.retrieved_date,
    h.status,
    h.notes,

    -- Hierarchy (self-referencing)
    h.parent_control_id_computed                                                                        as parent_control_id,
    case when h.parent_control_id_computed is not null
         then {{ dbt_utils.surrogate_key(['h.framework_code', 'h.parent_control_id_computed']) }}
         else null
    end                                                                                                 as parent_control_sk,
    h.root_control_id_computed                                                                          as root_control_id,
    h.hierarchy_level_computed                                                                          as hierarchy_level,
    (pr.parent_control_id_computed is null)                                                             as is_leaf,

    -- SCD2 metadata from snapshot
    h.dbt_valid_from                                                                                    as valid_from,
    h.dbt_valid_to                                                                                      as valid_to,
    (h.dbt_valid_to is null)                                                                            as is_current

from hier h
left join parent_refs pr
    on  pr.framework_code = h.framework_code
    and pr.parent_control_id_computed = h.control_id
