---
name: dbt-bind-governance
description: Propose and write the AI governance bindings for a dbt model that feeds an AI/LLM downstream. Auto-triggers when a model is tagged ai_consumed, or as a sub-step of dbt-create-model. Reads dim_ai_control candidate rules, proposes which apply, writes the schema.yml meta block and the bindings seed row, and runs the evidence query to confirm zero pre-existing violations.
---

# dbt-bind-governance

You are binding a new (or existing) dbt model to the AI governance control
layer. This is the differentiator of this dbt project — every model whose
output is consumed by an LLM, RAG, or persona has provable lineage from a
regulatory requirement to the SQL that satisfies it.

## When you run

- As a sub-step of `dbt-create-model` when the user confirms "AI-consumed: yes."
- Standalone when the user says "bind governance for `fct_X`" or "this
  model needs `dim_ai_control` bindings."
- As a review pass: when `/dbt-ai-review` finds a model tagged
  `ai_consumed` without bindings.

## Read first

1. `/docs/AI_GOVERNANCE_BINDING.md` — the rationale, the criterion, the
   binding shape, the warn-only default.
2. `seeds/ai_mart/ai_controls_seed.csv` — the live `dim_ai_control` rows.
3. `seeds/ai_mart/ai_control_bindings_seed.csv` — existing bindings; match
   the structure exactly.
4. The model's `schema.yml` — confirm tags and column shape.

## The proposal step

For each candidate model, list applicable controls filtered by:

- **Domain** — `stock`, `cfd`, `health`, `gov`, `cross` — match the
  control's `applies_to` field.
- **Layer** — staging is rarely AI-consumed directly; marts and reporting
  are the usual surfaces.
- **Output shape** — what does the AI downstream actually consume? Plain
  numbers (`fct_metric`) face different controls than free text or
  recommendations.

Then propose:

```
For fct_trade_intent (domain=cfd, AI-consumed):
  Candidate controls:
    AFSL_761G_BAS_01     — output attribution: persona + confidence + timestamp
    AFSL_912A_OBL_03     — record-keeping: 7-year audit trail
    MAS_FSG_N16_3_2      — no personalized advice
    NIST_AI_RMF_MEASURE_2_1 — confidence interval emitted
  Skip:
    AFSL_761G_BAS_02     — only applies to retail-direct surfaces, not internal mart
```

Each binding must come with a **satisfies** justification that an auditor
can read in 30 seconds. Don't write generic "model produces output" —
write the specific verifiable fact.

## The write step

Two files always:

### 1. Append to `schema.yml` under the model's `meta:`

```yaml
- name: fct_trade_intent
  config:
    tags: ['marts', 'cfd', 'ai_consumed']
  meta:
    ai_controls:
      - control_id: AFSL_761G_BAS_01
        satisfies: "Persona + confidence + emitted_at are all non-null on every row"
      - control_id: AFSL_912A_OBL_03
        satisfies: "Materialized as permanent table with 7-year retention policy"
      - control_id: MAS_FSG_N16_3_2
        satisfies: "Output is intent-only, no user-id; downstream advice formatting requires explicit user opt-in"
      - control_id: NIST_AI_RMF_MEASURE_2_1
        satisfies: "Confidence column tested via dbt_expectations.expect_column_values_to_be_between"
```

### 2. Append rows to `seeds/ai_mart/ai_control_bindings_seed.csv`

One row per (model, control). Schema is:

```csv
model_name,control_id,binding_type,evidence_query,failure_mode,registered_at
fct_trade_intent,AFSL_761G_BAS_01,output_attribution,"select count(*) from {{ ref('fct_trade_intent') }} where persona is null or confidence is null or emitted_at is null",warn_only,2026-06-21
```

`failure_mode` defaults to `warn_only` per the pilot-stage rule
(`feedback_pilot_availability_over_strictness`). Don't default to `block`
without a written customer requirement.

## The verify step

Before you tell the user "bindings written," run each evidence query
against dev:

```bash
dbt run --select <model>
dbt run-operation run_query --args "{sql: \"select count(*) from {{ ref('fct_trade_intent') }} where persona is null\"}"
```

Expected: every query returns zero. If any returns rows, the binding is
born broken — either the model has a real bug, or the binding's predicate
is wrong. Fix before declaring done.

## What to refuse

- **Binding a model that doesn't qualify as AI-consumed** — the criterion
  in `AI_GOVERNANCE_BINDING.md` is strict. False positives pollute the
  audit dashboard.
- **Adding a control_id that's not in the live seed** — fail loud. Don't
  silently invent control IDs.
- **`failure_mode: block` at pilot stage** without a customer-written
  justification.
- **A `satisfies:` description that's generic** — refuse and ask for the
  specific verifiable fact.

## Reporting back

When done, tell the user:

- Which controls were bound, with one-line justifications
- Which were considered and skipped, with reason
- Verification command to confirm bindings hold:
  `dbt build --select <model> +tag:ai_governance`
- Where the new bindings appear in the audit dashboard (governance
  surface, e.g., `https://platform.datap.ai/ai-governance`)
