# dbt conventions

Layering, materialization, refs vs sources, and the multi-vertical pattern
this repo uses. Read together with `SQL_CONVENTIONS.md` and `YAML_STYLE.md`.

## Layering

```
sources                 raw / external stage (Snowflake stage, S3, Iceberg)
   ↓
staging   stg_*         1:1 with source. Rename + cast + light cleanup.
   ↓
intermediate int_*      Multi-source joins, derived columns, business logic
                        intermediate steps. Not analytics-final.
   ↓
obt / marts fct_/dim_   Final analytics-ready. Stable schema.
   ↓
reporting   rpt_        BI semantic layer (Lightdash). Tagged "published".
```

`ai_mart/` is a **parallel mart**, not a 5th layer — it reads from
`reporting` and emits guardrail / audit / governance outputs.

## Materialization

| Layer | Default | When to override |
|---|---|---|
| `staging` | `table` | `view` for very wide PII tables where storage > compute. Set in `dbt_project.yml`. |
| `intermediate` | `table` | `view` for cheap CTEs that are only referenced once downstream. |
| `obt / marts` | `table` | `incremental` for fact tables > 100M rows or with stable partitioning. |
| `reporting` | `table` | `view` if BI tool can handle the cost (Lightdash + Snowflake usually can). |
| `ai_mart` | `view` | Almost never `table` — guardrails need to evaluate fresh, not snapshots. |

**Incremental** materialization needs:
- `unique_key` set (`unique_key='trade_intent_id'`)
- `on_schema_change='append_new_columns'` (safe default)
- `incremental_strategy='merge'` for Snowflake
- A `where {{ is_incremental() }}` clause filtering by `_loaded_at` or `emitted_at`

## ref() vs source()

- **`{{ ref('model_name') }}`** for everything defined inside this dbt project.
  Lineage depends on it; CI depends on it; the DAG depends on it.
- **`{{ source('source_name', 'table_name') }}`** for raw inputs declared in
  `sources.yml`. Lets staging be the single point of truth for source freshness.
- **Never `database.schema.table`** as a hardcoded reference. Breaks dev/staging/prod
  separation and breaks slim CI.

## Multi-vertical pattern

Each domain (`stock`, `chinook`, `full-jaffle-shop`) is a self-contained
subtree under `models/`, with its own `staging/`, optional `intermediate/`,
and its own marts. The cross-cutting concerns (`ai_mart/`, `elementary/`)
sit alongside.

Domain-level overrides live in `dbt_project.yml`:

```yaml
models:
  datapai:
    stock:
      +database: "{{ env_var('SNOWFLAKE_DATABASE', 'DATAPAI') }}"
      +schema: STOCK
      +tags: ['stock', 'ohlcv']
```

When adding a new vertical, follow this exact pattern — don't invent a new
layout. The Airflow DAGs and governance bindings rely on the
`models/<vertical>/<layer>/` structure to drive selection.

## Naming for tests + audit

- **Tests** in `tests/` are project-wide custom generic tests; per-model
  tests live in `schema.yml` under each column.
- **`tests:` schema** is `test_audit` (failures stored, limit 1000 rows
  per failure). See `dbt_project.yml`.
- **Elementary** writes to `audit` schema; don't mix custom test audit
  with Elementary's tables.

## State-aware CI (slim CI)

The PR workflow (`.github/workflows/dbt-slim-ci.yml`) runs only
modified-or-downstream models:

```bash
dbt build --select state:modified+ --defer --state ./prod-state/
```

This requires a **prod state snapshot** in `./prod-state/` from the last
merge — produced by `.github/workflows/dbt-merge.yml`.

When refactoring a macro or `sources.yml`, mass invalidation is expected
— that's the system working as designed, not a bug to avoid. Just expect
the full project to run on that PR.

## Macros — when to write one

Write a macro when:
- The same SQL pattern appears in **3+ models** (rule of three).
- The pattern depends on environment / schema (e.g., schema-renaming
  for Elementary).
- The pattern needs to be testable independently of any model.

Don't write a macro for:
- A single-use parameterization — inline it.
- "Cleanliness" — macros are harder to debug than copies.

Existing utility macros live in `macros/`. Read them before writing a
new one; many already exist (`_generate_schema_name.sql` is the schema
override hook, for example).

## Source freshness

Every source declared in `sources.yml` should have `freshness:` set:

```yaml
freshness:
  warn_after: { count: 6, period: hour }
  error_after: { count: 24, period: hour }
loaded_at_field: _loaded_at
```

Without freshness, downstream models can silently serve stale data.
Airflow runs `dbt source freshness` on every hourly tick.

## When dbt is the wrong tool

- **Sub-second latency**: dbt builds tables. Use ClickHouse Materialized
  Views (see the CFD branch in `datapai-cfd-be`) for sub-second.
- **OLTP**: dbt is OLAP. Aurora PostgreSQL is the OLTP layer.
- **Imperative API logic**: use a service (FastAPI). dbt is declarative
  data transformation, not application logic.
