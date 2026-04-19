{{
    config(
        materialized = 'view',
        schema       = 'ai_mart',
        tags         = ['ai_governance', 'stg']
    )
}}

{#
  Thin staging view over the external chat_history parquet archive.
  No redaction here — that's fct_ai_chat_message's job.
  Vertical hardcoded to 'stock' because this path only covers stock-be archive;
  health/trade will union in via their own external tables + UNION ALL.
#}

select
    message_id,
    session_id,
    session_user_id,
    ticker,
    exchange,
    session_title,
    session_created_at,
    role,
    content,
    model_used,
    context_sources,
    created_at         as event_at,
    archived_at,
    archive_run_id,
    dt_year,
    dt_month,
    dt_day,
    'stock'            as vertical
from {{ source('ai_chat_history', 'ext_chat_history') }}
