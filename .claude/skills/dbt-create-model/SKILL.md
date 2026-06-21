---
name: dbt-create-model
description: Scaffold a new dbt model (staging / intermediate / marts / reporting) following the datapai house conventions. Auto-triggers on requests like "add a model for X", "scaffold a staging model", or "create fct_xxx". Reads SQL_CONVENTIONS / YAML_STYLE / DBT_CONVENTIONS before writing. Composes with dbt-bind-governance for AI-consumed models.
---

# dbt-create-model

You are scaffolding a new dbt model in the `datapai` dbt project. The user
asked you to add a model; your job is to produce the `.sql` file, the
`schema.yml` entry, the seeds/tests/docs that go with it, and — if it
qualifies — the AI governance binding.

## Before you write anything

Read in order:

1. `/CLAUDE.md` — verticals, layers, conventions overview
2. `/docs/DBT_CONVENTIONS.md` — layering + materialization rules
3. `/docs/SQL_CONVENTIONS.md` — house SQL style
4. `/docs/YAML_STYLE.md` — schema.yml shape + required tests
5. `/docs/AI_GOVERNANCE_BINDING.md` (only if AI-consumed)
6. The closest existing model in the same domain/layer — match its
   structure exactly. Don't invent a parallel convention.

## What you need to know

Before scaffolding, confirm or default each:

| Question | Default |
|---|---|
| **Domain** (`stock`, `chinook`, `full-jaffle-shop`, `ai_mart`, new?) | infer from the model name; ask if ambiguous |
| **Layer** (`staging`, `intermediate`, `obt`/`marts`, `reporting`) | infer from the prefix (`stg_`, `int_`, `fct_`/`dim_`, `rpt_`) |
| **Source(s)** | ask the user; never invent |
| **Primary key** | required; the column that has `unique` + `not_null` |
| **AI-consumed?** (feeds an LLM / RAG / persona context) | ask; default no |
| **Materialization** | inherit from `dbt_project.yml` defaults; override only with a reason |

## What you produce

For a model `fct_trade_intent` in domain `cfd`, layer `marts`:

1. **`models/cfd/marts/fct_trade_intent.sql`** — the SQL, following
   `docs/SQL_CONVENTIONS.md` exactly. Final CTE named `final`. No
   `SELECT *` outside staging.

2. **`models/cfd/marts/schema.yml`** — append (or create) the model
   block with description, column-level `description:` + `data_type:`
   + `tests:`, and if AI-consumed, `meta.ai_controls`.

3. **If staging** — also add the source declaration to
   `models/<domain>/sources.yml` (with `freshness:` + `loaded_at_field:`).

4. **If AI-consumed** — hand off to `dbt-bind-governance` skill: propose
   `meta.ai_controls` and the matching row in
   `seeds/ai_mart/ai_control_bindings_seed.csv`.

5. **README touch** — only if a new domain or new layer is introduced.
   Don't touch on every model.

## The SQL skeleton (marts)

```sql
{{ config(
    materialized='table',
    tags=['marts', 'cfd', 'ai_consumed']
) }}

with

intent as (
    select * from {{ ref('int_trade_intent') }}
),

persona as (
    select * from {{ ref('dim_persona') }}
),

final as (
    select
        i.trade_intent_id,
        i.emitted_at,
        i.symbol,
        i.side,
        i.size,
        i.confidence,
        p.persona_name        as persona,
        p.persona_tier        as persona_tier
    from intent i
    inner join persona p
        on p.persona_id = i.persona_id
)

select * from final
```

## The schema.yml skeleton (marts, AI-consumed)

See `docs/YAML_STYLE.md` for the canonical shape. Include `data_type` on
every column with a `tests:` block, otherwise dbt contracts won't enforce.

## After scaffolding

Run mentally:
- `dbt compile --select <new_model>` — would this compile?
- `dbt test --select <new_model>` — would the column tests pass given
  realistic data?
- `dbt docs generate` — would the column descriptions render usefully?

Then tell the user:
- File paths created/modified
- Run command to verify: `dbt build --select <new_model>`
- Any governance bindings that need a one-time seed update

## What to refuse

- **No primary key declared** — ask for it; don't invent.
- **Mixing layers in one file** (a "staging-but-also-aggregating" file) — reject.
- **`select *` in a mart** — refuse, link to `SQL_CONVENTIONS.md`.
- **AI-consumed without a binding** — refuse, link to
  `AI_GOVERNANCE_BINDING.md` and run `dbt-bind-governance`.
- **New domain without updating `dbt_project.yml`** — that breaks schema
  overrides. Edit `dbt_project.yml` first.
