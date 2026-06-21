# YAML style

How `schema.yml`, `sources.yml`, and `dbt_project.yml` should look in this
repo. Mirror existing files; don't invent a parallel structure.

## File placement

- **One `schema.yml` per model folder**, alongside the `.sql` files it
  documents. Don't centralize.
- **`sources.yml`** at the root of each domain folder (e.g.,
  `models/stock/sources.yml`), one per source system.
- **Macros** — `macros/` flat; group with prefix (e.g., `_generate_schema_name`,
  `gov_audit_emit`) rather than subfolders.

## Indent + quoting

- **2 spaces**, no tabs.
- **No trailing whitespace**, file ends with one newline.
- **Single quotes** for string values; **no quotes** for YAML keywords
  (`true`, `false`, `null`).
- **Block scalars** for descriptions over ~80 chars (`description: |` or
  `description: >`); single line otherwise.

## schema.yml shape

Every model needs:

```yaml
version: 2

models:
  - name: fct_trade_intent
    description: |
      One row per trade intent emitted by a downstream AI persona. Includes
      the persona name, the symbol, the side, the size, the confidence, and
      the governance verdict.
    config:
      contract:
        enforced: true
    columns:
      - name: trade_intent_id
        description: Surrogate key — uuid v4.
        data_type: varchar
        constraints:
          - type: primary_key
        tests:
          - unique
          - not_null

      - name: emitted_at
        description: When the persona emitted this intent (UTC).
        data_type: timestamp_tz
        tests:
          - not_null

      - name: persona
        description: Which AI Trade Council persona emitted it.
        data_type: varchar
        tests:
          - not_null
          - accepted_values:
              values: ['bull', 'bear', 'risk', 'pm']

      - name: symbol
        description: Asset symbol, e.g. AAPL, BHP.AX, EURUSD.
        data_type: varchar
        tests:
          - not_null

      - name: confidence
        description: Persona's stated confidence, 0.0–1.0.
        data_type: numeric
        tests:
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 1
```

### Required column tests

| Column type | Required tests |
|---|---|
| Primary key | `unique` + `not_null` |
| Foreign key | `not_null` + `relationships` to the referenced dim |
| Enum | `accepted_values` |
| Timestamp | `not_null` |
| Numeric range | `dbt_expectations.expect_column_values_to_be_between` |
| PII column | `+tags: [contains_pii]` on the model |

## sources.yml shape

```yaml
version: 2

sources:
  - name: snowflake_raw
    description: Raw stage tables loaded from S3 by Airbyte.
    database: "{{ env_var('SNOWFLAKE_DATABASE', 'DATAPAI') }}"
    schema: raw
    freshness:
      warn_after: { count: 6, period: hour }
      error_after: { count: 24, period: hour }
    loaded_at_field: _loaded_at
    tables:
      - name: ohlcv_us
        description: US equity OHLCV, one row per symbol-day, loaded from S3.
        columns:
          - name: symbol
            tests:
              - not_null
          - name: trade_date
            tests:
              - not_null
```

## Tags

Tags are how Airflow / orchestration / governance pick which models to run.
Use the existing taxonomy — don't invent new tags casually.

| Tag | Meaning | Used by |
|---|---|---|
| `staging` | layer marker | airflow |
| `intermediate` | layer marker | airflow |
| `marts` | layer marker | airflow |
| `published` | safe for BI / downstream | Lightdash, airflow |
| `hourly` | run hourly | airflow hourly DAG |
| `daily` | run daily | airflow daily DAG |
| `contains_pii` | has PII columns | governance audit |
| `ai_consumed` | output feeds an AI/LLM | `dim_ai_control` binding required |
| `ai_governance` | this model IS governance plumbing | governance dashboard |
| `guardrail` | enforces a policy at query time | `dim_ai_control` |

## `dbt_project.yml`

Don't edit lightly. Schema overrides, materialization defaults, var
definitions are load-bearing. If you need a new var, add it under `vars:`
with a sensible default via `env_var()`, and update CLAUDE.md so the
context stays current.

## What NOT to do

- Don't write a 100-line description block. If a model needs a long
  explanation, link to a `docs/` page from a one-line description.
- Don't mix tabs and spaces — sqlfluff will complain and dbt won't parse.
- Don't quote integer-looking strings (`'2024'`) without intent — YAML
  handles those.
- Don't omit `data_type:` on a column that has a `tests:` block. The dbt
  contract + lineage docs depend on it.
