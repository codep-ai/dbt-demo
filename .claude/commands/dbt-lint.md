---
description: Run sqlfluff fix + lint on staged or changed SQL models.
---

Lint and auto-fix SQL in changed models.

```bash
# 1. Find changed model files
CHANGED=$(git diff --name-only --diff-filter=ACM HEAD | grep -E '^models/.*\.sql$' || true)

if [ -z "$CHANGED" ]; then
    echo "No changed SQL models."
    exit 0
fi

echo "Linting changed models:"
echo "$CHANGED" | sed 's/^/  /'

# 2. Auto-fix what sqlfluff can
sqlfluff fix --dialect snowflake --templater dbt --processes 4 $CHANGED

# 3. Lint what's left
sqlfluff lint --dialect snowflake --templater dbt --processes 4 $CHANGED
```

After fix:
- Re-stage the auto-fixed files: `git add models/`
- Re-run with `dbt-lint` to confirm zero violations

If lint still fails after fix:
- The remaining violations need manual review (sqlfluff can't auto-fix
  everything safely)
- Show the user the specific rule violations + suggested manual changes
  per `docs/SQL_CONVENTIONS.md`

Refuse to bypass lint with `# noqa` unless the violation is genuinely a
false positive (rare) and the user agrees in writing in the commit.
