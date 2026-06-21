---
description: Senior dbt engineer review of the current diff — SQL quality, missing tests, governance gaps, materialization choices, naming.
---

Review the current diff like a senior dbt engineer would. Be specific,
opinionated, and reference the canonical convention doc per finding.

## What to check

For each `.sql` file in the diff:

1. **Layering** — is the file in the right layer? `stg_` in `staging/`,
   `fct_/dim_` in `marts/`, etc. Cross-layer naming = automatic flag.
2. **Materialization** — does `+materialized:` in `dbt_project.yml` or
   `{{ config(materialized=…) }}` match what the model needs? Big marts
   should be `incremental`; tiny dims should be `view`.
3. **Naming** — every model + column follows
   `docs/SQL_CONVENTIONS.md#naming`.
4. **`SELECT *`** outside staging — automatic flag.
5. **`ref()` vs source()** — refs for internal, sources for raw. No
   hardcoded `database.schema.table`.
6. **CTEs** — top-down, named, one job per CTE. No subqueries where a
   CTE would read better.
7. **Joins** — `inner join` / `left join` explicit; columns qualified;
   condition on its own line.
8. **Window functions** — `order by` present where order matters; frame
   explicit when non-default.

For each changed `schema.yml`:

9. **Every column** has `description:` and (where it has tests)
   `data_type:`.
10. **Primary key** has `unique` + `not_null`.
11. **Enums** have `accepted_values`.
12. **Numeric ranges** have `expect_column_values_to_be_between`.
13. **Tag `ai_consumed`** → `meta.ai_controls` populated; if missing,
    FAIL and run `dbt-bind-governance`.

For each changed `sources.yml`:

14. **`freshness:`** set with sensible warn/error.
15. **`loaded_at_field:`** present.

For the diff as a whole:

16. **New macro** — does the rule of three apply? If only one model uses
    it, suggest inlining.
17. **New domain** — `dbt_project.yml` updated? CLAUDE.md updated?
18. **Dropped model** — is it ref'd elsewhere? Run `dbt list --select +<name>`
    on the prior commit.

## How to deliver

Per finding, give:
- File + line
- The rule (linked back to `docs/SQL_CONVENTIONS.md#<anchor>` or similar)
- Why it matters (one sentence — operational, governance, or quality risk)
- The fix (diff snippet)

Use this severity scale:
- **FAIL** — must fix before merge (broken governance binding,
  `SELECT *` in mart, missing PK test)
- **WARN** — should fix, mergeable with note (materialization
  inefficiency, missing description)
- **NOTE** — minor (capitalization, comment style)

End with a single one-line verdict: "Ship as-is" / "Fix FAILs first" /
"Block — see notes."
