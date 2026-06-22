# CLAUDE.md — `dbt-demo` (datapai multi-vertical dbt project)

> AI co-author context for this dbt project. Read this first.
> If anything below conflicts with what you observe in the repo, **trust the
> repo and update this file** — don't act on stale guidance.

## What this project is

A single dbt project that serves **four verticals** through one transformation
layer, governed end-to-end by an AI control layer:

| Domain folder | Purpose | Target schemas |
|---|---|---|
| `models/stock/` | US + ASX equity OHLCV, technical indicators, screener metrics | `STOCK` (Snowflake DB: `DATAPAI`) |
| `models/chinook/` | Reference dataset — music/sales analytics | `staging`/`intermediate`/`marts` |
| `models/full-jaffle-shop/` | Reference dataset — orders/customers | `staging`/`marts` |
| `models/ai_mart/` | **AI governance guardrails** — `dim_ai_control`, audit, decision logs | `ai_mart` |

The reusable wisdom lives in `macros/`, the cross-domain conventions live in
this file + `docs/`. Each vertical re-uses the same patterns — staging
discriminator pattern, ai_governance tagging, Elementary tests, dbt-expectations.

## Targets

- **Profile**: `datapai_snowflake` (Snowflake, key-pair auth via `airbyte_user`)
- **Adapter**: `dbt-snowflake` is the **one and only** dbt adapter we run.
  ClickHouse is fed by Kafka engine + Materialized View (CH-native ELT),
  not by dbt. See `docs/architecture/4-layer-lakehouse-narrative.md` in
  `datapai-cfd-be` for the decision.
- **Permanent tables** for stock; **views** for `ai_mart` (auditor-readable
  + no-cost guardrails); **tables** elsewhere.

## Portable SQL — the warehouse-portability discipline

> Models must compile cleanly on Snowflake **today** AND on ClickHouse
> **tomorrow** with minimal rewrite. This is a commercial promise we make
> to customers (TMGM in particular): if they later consolidate to
> ClickHouse-only to reduce SF spend, the migration is a 3–6 week dbt
> re-target — not a 12-month rewrite.

**Five rules to keep models portable:**

1. **Portable SQL subset by default.** Standard SELECT/JOIN/WHERE/GROUP BY,
   CTEs, window functions, standard aggregates. These compile on every
   adapter.
2. **SF-specific constructs go behind macros or `target.type` gates.**
   `QUALIFY`, `LATERAL FLATTEN`, `VARIANT`, `OBJECT_CONSTRUCT`, SF
   `MERGE` — wrap in a macro with a SF body and a CH body, OR gate with
   `{% if target.type == 'snowflake' %}` so the same model file emits
   different SQL per adapter without forking the file.
3. **Prefer `dbt_utils` + `dbt_expectations` over hand-rolled SQL.** Both
   ship cross-adapter implementations of the common patterns
   (`surrogate_key`, `pivot`, `expression_is_true`, etc.). Hand-rolled
   SF SQL is what bites at migration time.
4. **No `STREAMS` / `TASKS` (SF CDC).** Restructure CDC as a Kafka MV or
   an incremental dbt model with a watermark column. Portable to CH from
   day one.
5. **Use Iceberg as the SF table format (`table_format='iceberg'`).** When
   a customer migrates to CH-only, CH reads the same Iceberg files via
   the `iceberg()` table function — the data doesn't move. The migration
   becomes "stop writing from SF, start writing from CH" rather than a
   data-copy exercise.

When a model genuinely needs an SF-only feature (rare), document the
reason in a comment and add the gated CH alternative path. The
`/dbt-ai-review` skill flags un-gated SF-specific constructs as a finding.

## Layering (apply per domain)

```
sources (raw / external stage)
   ↓
staging   — 1:1 with source, rename + cast + light cleanup. Materialized: table.
   ↓
intermediate — multi-source joins, business logic intermediate steps. Table.
   ↓
obt / marts — final analytics-ready facts/dims. Table.
   ↓
reporting — BI-facing semantic layer. Table, tagged "published".
```

`ai_mart/` is the cross-cutting governance layer that reads from `reporting`
and emits guardrail outputs — it is **not** a 5th layer; it's a parallel mart.

## Non-negotiables — DO

- **One model per file**, filename = model name (snake_case).
- **`ref()`** for every internal reference; **`source()`** for every raw input
  named in `sources.yml`. Never hardcode `database.schema.table`.
- **`schema.yml`** alongside each model, with a `description:` per column and
  at least one test (`unique` or `not_null`) on the primary key.
- **CTEs over subqueries** — readable top-down, each CTE has one job.
- **Snake_case** for all identifiers; **`fct_*`** for facts, **`dim_*`** for
  dims, **`stg_*`** for staging, **`int_*`** for intermediate.
- **Governance tag** every model that produces an AI-consumed output:
  `+tags: [ai_consumed]`. The `dbt-bind-governance` skill enforces this.

## Non-negotiables — DON'T

- **No `SELECT *`** outside staging — name every column explicitly.
- **No hardcoded credentials, paths, or environment-specific values.**
  Use `env_var()` with a sane default — pattern is in `dbt_project.yml`.
- **No new mart without a governance tag and a `dim_ai_control` binding**
  if it feeds an AI/LLM downstream (see `docs/AI_GOVERNANCE_BINDING.md`).
- **No model > 500 lines.** Split into intermediate CTEs at the seam.
- **No direct edits to `dbt_packages/`, `target/`, `logs/`** — generated.

## House style for Claude

When asked to **scaffold a new model**, follow the `dbt-create-model` skill:
read `docs/SQL_CONVENTIONS.md`, `docs/YAML_STYLE.md`, `docs/DBT_CONVENTIONS.md`
before writing a line. Match the existing domain's patterns; never invent
a 5th layer or a parallel naming convention. If the new model feeds AI,
also propose the `dim_ai_control` binding (see `dbt-bind-governance` skill).

When asked to **debug a failing model**, follow `dbt-debug-failing-model`:
read the compiled SQL from `target/compiled/...`, walk the lineage with
`dbt list --select +<model>+`, only propose a fix once the upstream is
understood — never patch downstream symptoms.

When asked to **review a diff**, follow `/dbt-ai-review`: senior-engineer
mode, surface SQL anti-patterns, missing tests, governance gaps, and
materialization mistakes (e.g. a high-fan-out join materialized as `table`
when `view` would do).

## Standard commands

| Command | Purpose |
|---|---|
| `/dbt-add-model name=… layer=… domain=…` | Scaffold a model + schema.yml + governance row |
| `/dbt-run-changed` | Slim CI build of only changed models (uses `state:modified+`) |
| `/dbt-lint` | sqlfluff fix + lint on staged SQL |
| `/dbt-ai-review` | Senior-eng review of the current diff |

## Where to look first

- This file → context
- `docs/SQL_CONVENTIONS.md` → SQL house style
- `docs/YAML_STYLE.md` → schema.yml / sources.yml style
- `docs/DBT_CONVENTIONS.md` → layering + materialization rules
- `docs/AI_GOVERNANCE_BINDING.md` → how models bind to `dim_ai_control`
- `dbt_project.yml` → ground truth for schemas, tags, vars
- `models/ai_mart/` → governance examples

## What's NOT here yet (deliberately deferred)

- **Schema Registry / Avro** for source contracts — JsonConverter is sufficient
  for the current stock + CFD demo paths.
- **dbt Cloud orchestration** — we run via Airflow + dbt-core (see
  `~/git/datapai-dbt-governance/dags/`).
- **Per-tenant deployments** — single-tenant project today; the multi-tenant
  pattern lives in `datapai-platform-be/customer-vpc/`.

## Provenance

Project lives at `~/git/dbt-demo/` locally and on EC2 (`platform.datap.ai`).
**EC2 is the source of truth** for any live changes — reverse-sync to local
before committing. Run by Airflow under `~/git/datapai-dbt-governance/dags/`.
