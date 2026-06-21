---
name: dbt-debug-failing-model
description: Debug a dbt model that is failing in compile, build, or test. Auto-triggers on "this model is failing", "dbt error in X", or "why is Y returning wrong rows". Reads compiled SQL + lineage + test results before proposing a fix. Iron rule — fix root causes, never patch downstream symptoms.
---

# dbt-debug-failing-model

You are debugging a failing dbt model. The Iron Rule: **no fixes without
root cause.** Don't paper over a downstream symptom by adding a `coalesce`
or a `where` filter — find the upstream issue and fix it there, unless
the downstream patch is genuinely the correct boundary.

## Investigation order

1. **Read the error message** verbatim. Quote it back to the user so
   you both see the same thing.

2. **Identify which model** is failing. If the user said "the model" but
   there are several in the diff, ask which one.

3. **Read the compiled SQL** at `target/compiled/datapai/models/<path>.sql`.
   The compiled file is what actually ran — Jinja substitutions resolved,
   refs replaced. If `target/compiled/` is stale, run `dbt compile
   --select <model>` first.

4. **Walk the lineage upstream**:
   ```bash
   dbt list --select +<failing_model>+ --output path
   ```
   List every ref'd model and source. If any upstream is also failing,
   start there — failing model is a symptom.

5. **Check freshness**:
   ```bash
   dbt source freshness --select source:<source_name>
   ```
   Stale source can manifest as "weird row counts" or NULLs in
   downstream models.

6. **Read recent test failures**:
   ```bash
   dbt test --select <model> --store-failures
   # then: select * from test_audit.<test_name> limit 50;
   ```

7. **Check Elementary monitoring** in `audit` schema for anomalies
   (volume, freshness, distribution) leading up to the failure.

## Common failure modes

| Symptom | Root cause | Fix location |
|---|---|---|
| `Database Error: Object X does not exist` | Upstream model not built / wrong env | Upstream model, or profile |
| `Duplicate key value violates unique constraint` | Source has new dupes; staging dedup missing | Staging model |
| `Test unique on PK failed` | `staging` join introducing fan-out | The join in staging or intermediate |
| `Null in not_null column` | Source schema changed; staging assumes column exists | Staging cast / coalesce + alert on source schema drift |
| Compile error `'column does not exist'` | Schema drift in source; staging is stale | Update `stg_*` to match real source columns |
| Slow build (> 5x prior) | Missing clustering; or `+materialized: view` chained 4 deep | Materialization choice |
| `dbt build` succeeds but row counts are wrong | Filter pushdown lost; or join condition typo | The model where row count first drifts |

## When the fix is in this model

Acceptable downstream-only fixes:

- **Boundary safety** — coalesce at the staging/final select boundary
  where NULL is a known foreign-source behavior.
- **Defensive cast** — when source contract is `varchar` but data is
  actually numeric, cast in staging with a note.
- **Renaming** — when source columns are inconsistent, normalize at
  staging.

Not acceptable:

- **Hiding a bug** with `where x is not null` to make a test pass.
- **Adding a `distinct`** to silence a unique-test failure (find the dupe).
- **Lowering a test threshold** without a written justification.

## When to escalate to source

If staging is doing its job and intermediate / marts are still failing:

- **Source schema drift** — add a freshness + schema test to `sources.yml`
  and alert the source team. Don't keep silently absorbing.
- **Source data quality** — file a ticket on the source system; in the
  meantime, isolate the bad rows to an Elementary anomaly table for
  triage rather than dropping or hiding.

## How to report back

When you find the root cause, tell the user:

1. **What broke** — symptom, in their words.
2. **Why** — the actual mechanism (not "I added a fix"; explain *why* it
   broke).
3. **Where** — file path + line.
4. **The fix** — show the diff.
5. **What to verify** — `dbt build --select +<model>+` and which tests
   should now pass that weren't.

If you can't find the root cause after walking the lineage twice, stop
patching and ask the user. Better to admit you're stuck than to ship a
band-aid that hides the real problem.
