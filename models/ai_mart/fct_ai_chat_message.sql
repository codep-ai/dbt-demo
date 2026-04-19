{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'fct']
    )
}}

{#
  fct_ai_chat_message — per-LLM-turn fact for AI governance audit evidence.

  GRAIN: one row per chat message (user prompt or AI response).

  REDACTION
  ─────────
  `content` is NOT stored in this fact. Only SHA-256 hash + length are kept.
  Full text remains in the S3 Object Lock bronze layer (immutable, 7y retention).
  This satisfies auditor requirements without creating a duplicate PII surface
  in the warehouse.

  DIMS (current + future)
  ───────────────────────
  - dim_ai_control         — joins via future dim_ai_system.control_scope
  - dim_ai_system (future) — joins via agent_name / model_name
  - dim_ai_user   (future) — joins via session_user_id
  - dim_ai_session (future) — joins via session_id

  MEASURES
  ────────
  - tokens_used not in current parquet (column nullable in source); add
    backfill when archive pipeline includes it.
  - content_length (proxy for message size)
#}

with stg as (
    select * from {{ ref('stg_ai_chat_messages') }}
)
select
    {{ dbt_utils.surrogate_key(['session_id', 'message_id']) }} as message_sk,

    -- business keys
    message_id,
    session_id,
    session_user_id                            as user_id,
    vertical,
    ticker,
    exchange,
    role,
    model_used                                 as model_name,

    -- redacted content audit fields
    sha2(content, 256)                         as content_sha256,
    length(content)                            as content_length,
    context_sources,

    -- time grain
    event_at,
    session_created_at,
    archived_at,
    archive_run_id,
    dt_year,
    dt_month,
    dt_day,

    -- lineage
    current_timestamp()                        as fct_built_at
from stg
where content is not null
