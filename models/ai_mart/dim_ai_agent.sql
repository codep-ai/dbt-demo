{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'dim', 'agent']
    )
}}

{#
  dim_ai_agent
  ══════════════════════════════════════════════════════════════════════════
  GRAIN
  ─────
  One row per deployed AI agent (finest governable unit at DATAP.AI).
  "System" is a grouping column (multi-agent systems like Stock Debate
  Agent contain bull/bear/moderator/fundamental/technical/chart-vision
  sub-agents — each gets its own row).

  HIERARCHY AS COLUMNS (no mini-dims)
  ───────────────────────────────────
  Agent / System / Vendor / LLM / Governance / Lifecycle — all flat columns
  on this single dim. Group by any level via SELECT column:
    • GROUP BY system_name    → system-level rollup
    • GROUP BY domain         → vertical rollup
    • GROUP BY vendor_name    → model-provider rollup
    • GROUP BY llm_name       → foundation-model rollup
    • GROUP BY agent_role     → role rollup

  PRIMARY CONTROL FK
  ──────────────────
  primary_control_framework + primary_control_id resolve to dim_ai_control
  via control_sk = md5(framework_code || '.' || control_id). For queries
  needing the full control attributes, join:
    JOIN dim_ai_control c ON c.control_sk = {{ dbt_utils.surrogate_key(
      ['a.primary_control_framework', 'a.primary_control_id']
    ) }}
#}

with seed as (
    select * from {{ ref('ai_agents_seed') }}
)
select
    {{ dbt_utils.surrogate_key(['agent_key']) }}                               as agent_sk,
    agent_key,
    agent_name,
    agent_role,
    agent_framework,
    agent_purpose,
    system_name,
    domain,
    vendor_name,
    vendor_type,
    vendor_jurisdiction,
    llm_name,
    llm_capability_tier,
    llm_context_window,
    owner_user_id,
    owner_role_key,
    risk_tier,
    approval_status,
    primary_control_framework,
    primary_control_id,
    {{ dbt_utils.surrogate_key(['primary_control_framework', 'primary_control_id']) }} as primary_control_sk,
    deployed_at,
    decommissioned_at,
    case when decommissioned_at is null then true else false end as is_active,
    notes
from seed
