---
description: Slim-CI build of only changed-or-downstream models since last merge. Uses dbt state:modified+ and defers to the prod state snapshot.
---

Run a state-aware slim build of the dbt project.

```bash
# 1. Refresh the prod state snapshot (pulled from S3 by the CI workflow,
#    or copy from ./prod-state/ if local)
ls -la ./prod-state/manifest.json || {
    echo "Missing ./prod-state/manifest.json — pull from latest main run:"
    echo "  aws s3 cp s3://datapai-dbt-state/main/manifest.json ./prod-state/"
    exit 1
}

# 2. Build only modified-or-downstream models
dbt build \
    --select state:modified+ \
    --defer \
    --state ./prod-state/ \
    --fail-fast
```

If the diff includes macro or sources.yml changes, expect mass invalidation
— that's the system working as designed, not a bug.

If the build fails, invoke `dbt-debug-failing-model` skill on the first
failing model.

Report:
- Models built (count + first few names)
- Tests run + pass/fail count
- Wall-clock time
- Whether any models still need a manual `dbt build --select <X>` follow-up
