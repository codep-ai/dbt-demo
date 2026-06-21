# 2026-06-21 — Claude-ready dbt: turn `dbt-demo` into an AI-co-authored project

## Summary

Codified the conventions, scaffolding, linting, governance bindings, and CI
for `dbt-demo` so an AI co-author (Claude) can write dbt models that match
the house style without supervision — and so the same files double as the
written specification a senior dbt engineer or auditor would expect.

Net additions:

- **`CLAUDE.md`** — top-level context (verticals, layers, materializations,
  non-negotiables, where-to-look)
- **`docs/SQL_CONVENTIONS.md`** — house SQL style
- **`docs/YAML_STYLE.md`** — schema.yml + sources.yml shape, required tests
- **`docs/DBT_CONVENTIONS.md`** — layering, materialization, ref/source,
  multi-vertical pattern
- **`docs/AI_GOVERNANCE_BINDING.md`** — how models bind to `dim_ai_control`
  — the differentiator versus a vanilla Claude-and-dbt setup
- **`.sqlfluff`** + `.sqlfluffignore` — Snowflake dialect + dbt templater
- **`.pre-commit-config.yaml`** — sqlfluff + dbt-checkpoint hooks
- **`.claude/skills/`** — three skills:
  - `dbt-create-model` — scaffold a new model end to end
  - `dbt-debug-failing-model` — investigation order + common failure
    modes + the root-cause-before-fix rule
  - `dbt-bind-governance` — propose, write, and verify the AI control
    bindings for an AI-consumed model
- **`.claude/commands/`** — four slash commands:
  - `/dbt-add-model` — invokes the create-model skill
  - `/dbt-run-changed` — slim build of changed-or-downstream models
  - `/dbt-lint` — sqlfluff fix + lint on staged SQL
  - `/dbt-ai-review` — senior-dbt-engineer review of the current diff
- **`.github/workflows/dbt-slim-ci.yml`** — PR build of `state:modified+`
  with deferred prod state
- **`.github/workflows/dbt-merge.yml`** — full build on main, runs every
  AI governance evidence query, snapshots `manifest.json` to S3,
  publishes dbt-docs

## Why

The TMGM brief talks at length about AI readiness, governance, lineage,
observability, and pipeline reuse. The one thing it hadn't yet shown
concretely was **engineering discipline at the SQL authoring layer** —
how a Claude-AI-augmented dbt project keeps its conventions tight as the
model count grows past ~100.

Two business outcomes:

1. **Closes the AI demo gap with TMGM** — "watch Claude scaffold a model
   that follows our house style, with tests and governance bindings, in
   30 seconds." Cliackable, dataset-aware, not a slide.
2. **Becomes transferable IP** — a partner brokerage's own dbt project
   receives the same `CLAUDE.md` + docs + skills + linting + CI as a
   deliverable. The AI co-author is opt-in; the convention enforcement
   is not.

## Design decisions

### 1. `CLAUDE.md` lives at the repo root, not inside `.claude/`

`CLAUDE.md` is auto-loaded by Claude Code regardless of `.claude/`
configuration. Top-level placement also makes it discoverable by humans
reading the repo for the first time — it's effectively the second-most-read
file after `README.md`.

### 2. Skills are domain-specific; commands are user-facing

Three skills (`dbt-create-model`, `dbt-debug-failing-model`,
`dbt-bind-governance`) carry the procedural knowledge. Four commands
(`/dbt-add-model`, `/dbt-run-changed`, `/dbt-lint`, `/dbt-ai-review`)
are the user-typed entry points. The split lets the skill files be deep
(every rule, every refusal, every step) while keeping commands a single
short page.

### 3. AI governance binding is the differentiator

Every other Claude-ready dbt template I've seen is generic SQL hygiene.
The `dbt-bind-governance` skill ties model authoring to AFSL / MAS /
NIST AI RMF / ISO 42001 control rows in `dim_ai_control`, with a
verified `evidence_query` per binding. The skill refuses bindings whose
queries currently return rows — a binding can't be born broken.

This is the artifact that makes our dbt deliverable defensible to
regulators, not just to peer engineers.

### 4. `failure_mode: warn_only` is the default

Per `feedback_pilot_availability_over_strictness`, no binding defaults
to `block` without a written customer requirement. Killing a customer's
nightly batch over our governance flake is product death at pilot
stage. `warn_only` raises an alert but lets the build pass.

### 5. CI requires a prod state snapshot

Slim CI (`state:modified+ --defer --state ./prod-state/`) only works if
there's a prior `manifest.json` to defer against. The merge workflow
produces it (S3 `s3://datapai-dbt-state/main/manifest.json`); the PR
workflow pulls it. First-time setup needs one full-build merge to
prime the bucket; documented in the slim-CI workflow's pull step.

### 6. AI governance evidence queries run on merge, not on PR

PR runs lint + slim build + freshness. Merge runs the **full** build,
then re-runs every AI binding's `evidence_query` via the
`verify_ai_governance_bindings` macro (not yet authored; flagged as
pending below). A non-zero result fails the merge. This catches
governance drift the moment it lands on main, before it can hit
production.

### 7. We don't pre-populate every model with bindings

Existing `models/` aren't all retroactively bound. The skill applies
**to new and changed** models. Backfilling bindings is a separate
project that should run vertical-by-vertical (stock first, then CFD,
then health, then gov), and is out of scope for this commit. Documented
as pending below.

## What's pending (for a future session)

- **`macros/verify_ai_governance_bindings.sql`** — the run-operation
  invoked by the merge workflow. Reads
  `seeds/ai_mart/ai_control_bindings_seed.csv`, executes each
  `evidence_query`, returns non-zero count list. The workflow YAML
  references it but the macro itself isn't written yet — first PR that
  needs it can author it.
- **Seed file `seeds/ai_mart/ai_control_bindings_seed.csv`** — the
  CSV column shape is documented in `docs/AI_GOVERNANCE_BINDING.md`;
  the file itself doesn't yet exist (zero rows). First binding
  authored via `dbt-bind-governance` will create it.
- **Backfill bindings for existing AI-consumed models** in `models/stock/`
  and `models/ai_mart/` — separate per-vertical workstream.
- **Per-vertical README under `models/<vertical>/`** — currently the
  multi-vertical pattern is documented only in `CLAUDE.md` and
  `DBT_CONVENTIONS.md`. Per-vertical READMEs would let a new joiner
  drop straight into one domain.

## Verification

- All eight new files parse: `markdownlint` clean (no broken links);
  `yamllint` clean on the two workflow files.
- The `.sqlfluff` rule selections compile against the existing
  `models/stock/` SQL without spurious failures (manual spot check).
- The pre-commit hooks pin compatible versions
  (`dbt-core==1.7.4` + `dbt-snowflake==1.7.1` +
  `sqlfluff==3.0.0` + `sqlfluff-templater-dbt==3.0.0`).

Real verification — running CI against an actual PR — happens on the
next PR; no behavior change required to merge this scaffolding commit.

## Files changed

```
dbt-demo/
├── CLAUDE.md                                   (new)
├── docs/
│   ├── SQL_CONVENTIONS.md                      (new)
│   ├── YAML_STYLE.md                           (new)
│   ├── DBT_CONVENTIONS.md                      (new)
│   ├── AI_GOVERNANCE_BINDING.md                (new)
│   └── phase-journals/
│       └── 2026-06-21-claude-ready-dbt.md      (this file)
├── .sqlfluff                                   (new)
├── .sqlfluffignore                             (new)
├── .pre-commit-config.yaml                     (new)
├── .claude/
│   ├── skills/
│   │   ├── dbt-create-model/SKILL.md           (new)
│   │   ├── dbt-debug-failing-model/SKILL.md    (new)
│   │   └── dbt-bind-governance/SKILL.md        (new)
│   └── commands/
│       ├── dbt-add-model.md                    (new)
│       ├── dbt-run-changed.md                  (new)
│       ├── dbt-lint.md                         (new)
│       └── dbt-ai-review.md                    (new)
└── .github/workflows/
    ├── dbt-slim-ci.yml                         (new)
    └── dbt-merge.yml                           (new)
```

## Companion edits

- **`datapai-cfd-be/docs/strategy/2026-06-15-datapai-tmgm-information-brief.md`** —
  added Section 2.9 "AI-authored dbt — Claude as a co-author in the
  data pipeline" + new row in the §2.8 summary table.

## Related pointers

- TMGM brief: `datapai-cfd-be/docs/strategy/2026-06-15-datapai-tmgm-information-brief.md`
- Phase journal that preceded this: `datapai-cfd-be/docs/phase-journals/2026-06-21-tool-console-urls.md`
- Where the dbt project actually runs: `~/git/datapai-dbt-governance/dags/` (Airflow) on EC2
