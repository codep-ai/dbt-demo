# AI governance binding — how dbt models tie into `dim_ai_control`

This is what separates this dbt project from a vanilla one: **every model
whose output is consumed by an AI/LLM downstream must declare which
governance rules apply.** The binding is enforced at build time, surfaced
in audit, and reviewed by the `dbt-bind-governance` Claude skill.

This is also the doc to read when a regulator (ASIC, APRA, MAS) asks "how
do you ensure your AI follows your stated governance?"

## The four pillars

`dim_ai_control` is one row per atomic control statement, derived from:

1. **AFSL** — s761G (financial product advice), s912A (general obligations)
2. **MAS Notice FSG-N16** — Singapore guidance on AI use in financial advice
3. **NIST AI RMF** — risk management framework (MAP, MEASURE, MANAGE, GOVERN)
4. **ISO 42001** — AI management system requirements

Each row has:
- `control_id` (e.g., `AFSL_761G_BAS_01`)
- `framework`, `clause`, `requirement`
- `applies_to` (data domains, model layers, AI surfaces)
- `verification` (the test that proves compliance)
- `failure_mode` (`warn_only` default — pilot stage)

Live seed: `seeds/ai_mart/ai_controls_seed.csv`.

## The binding pattern

Every model that satisfies the AI-consumed criterion (defined below) must
declare its bindings in two places:

### 1. In `schema.yml`, under `meta.ai_controls`:

```yaml
models:
  - name: fct_trade_intent
    config:
      tags: ['ai_consumed', 'ai_governance']
    meta:
      ai_controls:
        - control_id: AFSL_761G_BAS_01
          satisfies: "Output marked with persona attribution + confidence + timestamp"
        - control_id: MAS_FSG_N16_3_2
          satisfies: "No personalized advice — outputs are educational scenarios only"
        - control_id: NIST_AI_RMF_MEASURE_2_1
          satisfies: "Confidence interval emitted with every intent"
```

### 2. In `seeds/ai_mart/ai_control_bindings_seed.csv` as one row per (model, control):

```csv
model_name,control_id,binding_type,evidence_query
fct_trade_intent,AFSL_761G_BAS_01,output_attribution,select count(*) from {{ ref('fct_trade_intent') }} where persona is null or confidence is null
```

The `evidence_query` becomes a runtime guardrail in `ai_mart/` — a view
that returns row counts. If non-zero, the binding is broken.

## The AI-consumed criterion

A model is "AI-consumed" if **any** of these is true:

- Its output feeds an LLM prompt (RAG retriever, persona context, fine-tune
  data).
- Its output is rendered to a user with AI-generated text alongside it.
- Its output is used to gate an AI action (allow/deny, throttle, route).
- It exists to **govern** other AI models (`dim_ai_control` itself counts).

If yes → must have bindings. If no → tag `ai_consumed` is **not** allowed
(audit will flag false positives).

## When Claude scaffolds a model

The `dbt-bind-governance` skill is invoked automatically by the
`dbt-create-model` skill when the new model's domain is `stock`, `cfd`,
`health`, or `ai_mart`. The skill:

1. Asks: "is this model AI-consumed?" (yes/no).
2. If yes, lists the candidate controls from `dim_ai_control` filtered by
   the model's domain and layer.
3. Proposes which controls apply, with the `satisfies:` justification.
4. Writes both the `schema.yml` `meta.ai_controls` block and the seed row.
5. Runs the evidence query against the existing data to verify it currently
   returns zero (otherwise the binding is born broken).

## When Claude reviews a diff

The `/dbt-ai-review` command checks:
- Any new model tagged `ai_consumed` without bindings → FAIL.
- Any new binding whose evidence query returns rows on dev data → FAIL.
- Any removed binding without a deprecation note → WARN.
- Any control_id not present in the live seed → FAIL.

## Why this matters commercially

This is the differentiator. Every dbt consultancy can write a `fct_orders`.
The thing TMGM / AFSL-licensed brokers / regulated fintechs actually need
is **provable, model-level traceability** from a regulatory requirement
to the SQL that satisfies it. The binding files above are auditor-readable:
"show me which dbt model satisfies AFSL s761G subsection 1." `grep` answers
it in 200 milliseconds.

## The "warn_only" default

At pilot stage, every binding's `failure_mode` is `warn_only` — a broken
binding raises an alert but does **not** block the dbt build. Once a
customer goes live and we have a year of clean runs, the failure_mode
flips to `block`. See `feedback_pilot_availability_over_strictness` —
killing customer batches over our governance flake is product death at
pilot.

## What's NOT covered yet

- **Prompt-level controls** (`ai_mart/dim_ai_prompt_control`) — proposed
  but not built.
- **Model card emission** — dbt-docs generates lineage; we don't yet
  emit model cards in the NIST format. Defer until a customer asks.
- **Differential privacy bindings** — applies once we have a healthcare
  customer; not relevant for stock/CFD.
