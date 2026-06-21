---
description: Scaffold a new dbt model with conventions, tests, schema.yml, and (if AI-consumed) governance bindings.
argument-hint: name=<model_name> layer=<staging|intermediate|marts|reporting> domain=<stock|cfd|health|ai_mart|...> [ai_consumed=true]
---

Invoke the `dbt-create-model` skill to scaffold the new model.

The user provided arguments: $ARGUMENTS

Parse them:
- `name=` — the model name (e.g., `fct_trade_intent`, `stg_orders`)
- `layer=` — staging / intermediate / marts (obt) / reporting
- `domain=` — which subfolder under `models/` (stock, cfd, health, ai_mart, etc.)
- `ai_consumed=true` — optional; if set, also invoke `dbt-bind-governance`

Before writing any file, **read** in order:
1. `/CLAUDE.md`
2. `/docs/DBT_CONVENTIONS.md`
3. `/docs/SQL_CONVENTIONS.md`
4. `/docs/YAML_STYLE.md`
5. `/docs/AI_GOVERNANCE_BINDING.md` (only if ai_consumed)
6. The nearest existing model in the same domain + layer

Then produce:
- `models/<domain>/<layer>/<name>.sql`
- Append or create `models/<domain>/<layer>/schema.yml` for the model
- If staging: also update `models/<domain>/sources.yml`
- If ai_consumed: hand off to `dbt-bind-governance`

Report back with file paths created and the command to verify:
`dbt build --select <name>`.
