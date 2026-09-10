{% docs __overview__ %}

## Data Documentation for Jaffle Shop

`jaffle_shop` is a fictional ecommerce store.

This [dbt](https://www.getdbt.com/) project is for testing out code.

The source code can be found [here](https://github.com/clrcrl/jaffle_shop).



## Column-level lineage

dbt shows table-level lineage here. **Column-level** lineage for the AI-generated models (tag `stock_ai`) is on the
[column lineage page](assets/lineage.html) — search a column, click it to highlight upstream (orange) and
downstream (green) paths; the colour bar is the PII sensitivity propagated from the raw sources.
Each column's `meta.lineage` / `meta.sensitivity` on the model pages is the same data. System of record:
`datapai.sys_ai_column_lineage` (framework Postgres), written by `datapai-ai-etl` on every lineage run.
Example: [fct_daily_price.close_usd](assets/lineage.html#fct_daily_price.close_usd).

{% enddocs %}
