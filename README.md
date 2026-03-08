# dbt-demo — Datap.ai Guardrail Demonstration Projects

This folder contains three dbt demo projects that serve as both runnable examples
and fixture sources for the Datap.ai AI Guardrail Framework.

---

## Projects

| Project | Domain | Models | Purpose |
|---------|--------|--------|---------|
| `full-jaffle-shop` | e-commerce | orders, customers, products, payments, refunds, returns, customer_lifetime_value | Core B2C data with PII, finance, and operational models |
| `chinook` | music streaming | albums, artists, tracks, invoices, customers, employees, playlists | Media and billing with HR-sensitive data |
| `stock` | equities | *(future)* | Market data domain |

---

## AI Governance Coverage

### full-jaffle-shop

| Model | AI Status | Scenario demonstrated |
|-------|-----------|----------------------|
| `orders` | ✅ certified | Aggregate-only — revenue model, no PII |
| `customers` | ✅ approved | PII present (name, email) — masked fields, RAG-approved |
| `products` | ✅ certified | Fully open — catalogue data, low sensitivity |
| `payments` | ⚠️ restricted | Financial data — aggregate-only, agent actions denied |
| `refunds` | ⚠️ restricted | Finance + PII — masked, BI metric explanations only |
| `returns` | ✅ approved | Operational — approved for explanation, metadata-only for export |
| `customer_lifetime_value` | ✅ certified | Derived metric — fully open for AI, export approved |

### chinook

| Model | AI Status | Scenario demonstrated |
|-------|-----------|----------------------|
| `albums` | ✅ certified | Open catalogue — fully AI-approved |
| `artists` | ✅ certified | Open catalogue — fully AI-approved |
| `tracks` | ✅ approved | Media metadata — open for retrieval and explanation |
| `invoices` | ⚠️ restricted | Billing data — aggregate-only, no export |
| `customers` | ✅ approved | PII model — masked fields (email, phone, address) |
| `employees` | 🚫 internal | HR-sensitive — no RAG, no export, limited AI access |
| `playlists` | ✅ certified | User-generated content — open for AI |
| `playlist_tracks` | ✅ approved | Junction model — filter-only fields, aggregate queries |

---

## Governance Patterns Illustrated

### 1 — Certified open model (`products`, `albums`, `artists`, `playlists`)
```yaml
ai_enabled: true
certified_for_ai: true
ai_access_level: approved
sensitivity_level: low
default_answer_mode: full
rag_exposure: allowed
```
*All AI use cases permitted. Fields freely selectable.*

### 2 — PII model with masking (`customers`)
```yaml
ai_enabled: true
ai_access_level: approved
contains_pii: true
default_answer_mode: masked
```
Column-level:
```yaml
- name: email
  meta:
    datapai:
      pii_class: direct
      masking_rule: redact
      allowed_in_output: false
      allowed_in_retrieval: false
```
*Model is AI-approved but direct identifiers are redacted. Aggregate counts and non-PII fields are freely queryable.*

### 3 — Aggregate-only finance model (`payments`, `invoices`)
```yaml
ai_enabled: true
ai_access_level: restricted
default_answer_mode: aggregate_only
export_policy: deny
agent_action_policy: deny
```
*AI can answer "total revenue by month" but never expose individual rows. Export and agent actions blocked.*

### 4 — HR-internal model (`employees`)
```yaml
ai_enabled: true
ai_access_level: internal
sensitivity_level: high
contains_pii: true
rag_exposure: deny
export_policy: deny
summarization_policy: deny
agent_action_policy: deny
```
*Model is accessible only for metadata explanation. No retrieval, no summarization, no export.*

### 5 — Quality-sensitive eligibility
The guardrail mart layer (`ai_mart/`) extends these static policies with Elementary
quality signals at runtime:

- If `fct_ai_asset_quality.quality_gate_status = 'tests_failed'` → model blocked
- If `quality_gate_status = 'warning'` → response includes a freshness / quality warning
- If `quality_gate_status = 'run_failed'` → model blocked regardless of policy
- If `quality_gate_status = 'pass'` → policy-driven answer mode applies normally

---

## The Guardrail Mart Layer (`models/ai_mart/`)

These five dbt models compile AI governance metadata into warehouse-queryable tables,
enriched with Elementary observability signals:

```
dim_ai_governed_assets          — one row per governed model; policy + Elementary ops
dim_ai_governed_fields          — one row per governed column; effective field policy
fct_ai_asset_quality            — Elementary quality gate signals per asset
fct_ai_policy_catalog_versions  — policy snapshot per dbt invocation
fct_ai_asset_runtime_eligibility — 16 AI use cases × N assets; eligibility grid
```

### Seeds (`seeds/ai_mart/`)

Two CSV seeds compile the `ai_governance.yml` YAML into SQL-queryable form:

| Seed | Rows | What it contains |
|------|------|-----------------|
| `ai_governed_assets_seed.csv` | 14 | One row per governed model; all model-level policy fields |
| `ai_governed_fields_seed.csv` | 54 | One row per governed column; all field-level policy fields |

These seeds can be queried directly and are the source-of-truth for the mart joins.

---

## Running the Demo

### Prerequisites

```bash
# Install dbt packages (Elementary, audit_helper)
cd dbt-demo
dbt deps

# Seed policy catalog
dbt seed --select ai_mart

# Build the guardrail mart layer
dbt run --select ai_mart

# Run quality checks
dbt test --select ai_mart

# (Optional) View schema drift analysis
dbt compile --select analyses.ai_schema_drift_check
```

### Querying the Marts

```sql
-- Which models are AI-eligible right now?
SELECT model_name, eligibility_status, ai_access_level, latest_run_status
FROM ai_mart.dim_ai_governed_assets
WHERE is_ai_enabled AND eligibility_status != 'blocked';

-- Which fields are safe for output?
SELECT model_name, column_name, effective_field_policy
FROM ai_mart.dim_ai_governed_fields
WHERE can_appear_in_output;

-- Are any models blocked by quality gates?
SELECT model_name, quality_gate_status, quality_gate_reason, latest_quality_score
FROM ai_mart.fct_ai_asset_quality
WHERE should_block_ai_use;

-- Runtime eligibility for text2sql
SELECT model_name, runtime_eligibility_status, runtime_answer_mode, runtime_reason_summary
FROM ai_mart.fct_ai_asset_runtime_eligibility
WHERE ai_use_case = 'text2sql';
```

---

## Lightdash Dashboards

The mart models are designed for direct use in Lightdash:

| Table | Suggested dashboard | Key metrics |
|-------|--------------------|-----------:|
| `dim_ai_governed_assets` | AI Asset Inventory | is_certified_for_ai, is_pii_model, is_restricted |
| `fct_ai_asset_quality` | Quality Gate Monitor | quality_gate_status, latest_quality_score, should_block_ai_use |
| `fct_ai_asset_runtime_eligibility` | Eligibility Matrix | runtime_eligibility_status by use_case |
| `fct_ai_policy_catalog_versions` | Policy Version History | pct_assets_certified, pct_fields_output_safe |

All boolean columns (`is_*`, `can_*`, `should_*`) render directly as Lightdash filters and table calculations.

---

## Connection to the Python Guardrail Layer

The `guardrail/warehouse_compiler.py` module reads these marts at runtime:

```python
from guardrail import WarehousePolicyCompiler

compiler = WarehousePolicyCompiler(conn=db_conn, schema="ai_mart")
catalog  = compiler.compile()

# Check a specific asset
policy = compiler.get_asset_policy("customers")
print(policy.ai_access_level)       # AiAccessLevel.APPROVED
print(policy._quality_gate_status)  # "pass" | "warning" | "tests_failed" …

# Check runtime eligibility
eligibility = compiler.get_runtime_eligibility("customers", "text2sql")
print(eligibility["runtime_eligibility_status"])  # "eligible" | "blocked"
```

See `docs/elementary_guardrail.md` for full integration guide.
