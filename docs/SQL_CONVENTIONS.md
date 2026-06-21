# SQL conventions

House rules for SQL in this dbt project. Enforced by `.sqlfluff` where
possible; reviewed manually otherwise. Updated when a real bug or review
finding teaches us something — not aspirationally.

## Naming

- **snake_case** for tables, columns, CTE aliases, model files. Never
  camelCase or PascalCase.
- **Singular** for column names (`customer_id`, not `customers_id`);
  **plural** for table names where the row is an entity (`customers`,
  `orders`). Facts are an exception: `fct_trade_intent` is fine (intent
  is the entity being recorded).
- **Prefixes** are semantic:
  | Prefix | Meaning |
  |---|---|
  | `stg_` | staging — 1:1 with source, renamed/cast |
  | `int_` | intermediate — joined/derived, not analytics-final |
  | `fct_` | fact — events, transactions, decisions |
  | `dim_` | dimension — entity attributes, slowly changing |
  | `rpt_` | reporting — BI semantic layer |
  | `bridge_` | many-to-many association |

## Structure

- **CTEs over subqueries.** Read top-down, one CTE per concern.
- **Final select last**, named `final` by convention.
- **Each CTE has a header comment** if its purpose isn't obvious from the
  alias.

```sql
with

source as (
    select * from {{ ref('stg_orders') }}
),

-- one row per customer, with their lifetime totals
customer_lifetime as (
    select
        customer_id,
        count(*)             as order_count,
        sum(order_amount)    as lifetime_value,
        min(order_date)      as first_order_at,
        max(order_date)      as latest_order_at
    from source
    group by customer_id
),

final as (
    select * from customer_lifetime
)

select * from final
```

## Selecting columns

- **Never `SELECT *` outside staging.** Name every column explicitly so
  schema changes upstream don't silently re-shape downstream models.
- **One column per line**, comma at end (sqlfluff enforces).
- **Order**: keys first (`*_id`), then attributes, then audit columns
  (`created_at`, `updated_at`, `_loaded_at`).

## Joins

- **Always qualify columns** with table or CTE alias when there's more than
  one table in scope.
- **Explicit `inner join`** — not just `join` — so intent is unmistakable.
- **Join condition on its own line**, indented under `on`.

```sql
from {{ ref('int_orders') }} o
inner join {{ ref('dim_customer') }} c
    on c.customer_id = o.customer_id
left join {{ ref('dim_product') }} p
    on p.product_id = o.product_id
```

## Window functions

- **Always include `order by` in `over()` for analytic functions** that
  depend on order (`row_number`, `lag`, `lead`, cumulative sums).
- **Frame clause** explicit when it matters — don't rely on the default.

```sql
sum(order_amount) over (
    partition by customer_id
    order by order_date
    rows between unbounded preceding and current row
) as customer_running_total
```

## Casts and conversions

- **Explicit casts at staging only.** Don't cast in marts — assume staging
  already cast correctly.
- **`::date`, `::timestamp_tz`, `::numeric(18,4)`** for Snowflake; never
  rely on implicit casting from string.
- **Timezones**: store as `timestamp_tz` in UTC, convert at the BI / API
  boundary. Never `timestamp_ntz` for event data.

## Date math

- Use `dateadd`, `datediff`, `date_trunc` — never raw integer arithmetic.
- **`current_date`** at staging only; downstream models should reference
  the staging row's `_loaded_at` to remain idempotent.

## NULLs

- **Test `is null` explicitly** — never assume `= null` works.
- **Coalesce at the boundary** (staging or final select), not mid-CTE,
  so the rest of the model sees consistent values.
- **NULL is meaningful**: don't silently `coalesce(x, 0)` if 0 is a
  valid business value distinct from "unknown."

## Anti-patterns to refuse

If a draft model contains any of these, refuse to ship and explain why:

| Anti-pattern | Why it's bad | Fix |
|---|---|---|
| `select *` in a mart | Schema drift downstream | Name columns |
| Hardcoded `'YYYY-01-01'` cutoff | Breaks at year boundary | `dateadd('year', -1, current_date)` or a var |
| Materialization `+materialized: table` on a 1-row config | Wasted storage | `view` |
| Cross join without filter | Cartesian blow-up | Add explicit join condition or `where` |
| `case when col = 'x' then 1 else 0 end` for booleans | Snowflake has `boolean` | `col = 'x'` |
| Magic numbers without comment | Unmaintainable | Pull into a var or comment |

## Comments

- **Why, not what.** `-- exclude internal accounts` not `-- where customer_type = 'internal'`.
- **Section headers** every ~30 lines if the model is long, with `-- ── ... ──`.
- **No dead code.** Delete commented-out blocks; git history remembers.
