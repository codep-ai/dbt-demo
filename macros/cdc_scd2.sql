-- Convert a CDC table where dms_utc_ts is the timestamp of the change
-- and delta_operation is the INSERT/UPDATE/DELETE operation by the source database
-- into a SCD2 table with from_ts and to_ts columns

-- source_schema: the schema of the source table
-- source_table: the name of the source table
-- pk: the name of the primary key column in the source table

{% macro cdc_scd2(source_schema, source_table, pk) %}

with ranked as (
    -- Select all rows from the source table, and add a row number column based on the primary ke
    -- and ordered by timestamp
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY {{pk}} ORDER BY dms_utc_ts::TIMESTAMP) AS row_num,
        ROW_NUMBER() OVER (
            PARTITION BY {{pk}}, DATE_TRUNC('day', dms_utc_ts AT TIME ZONE 'Australia/Sydney')
            ORDER BY dms_utc_ts DESC
        ) AS row_num_au,
        ROW_NUMBER() OVER (
            PARTITION BY {{pk}}, DATE_TRUNC('day', dms_utc_ts AT TIME ZONE 'Asia/Singapore')
            ORDER BY dms_utc_ts DESC
        ) AS row_num_sg,
        ROW_NUMBER() OVER (
            PARTITION BY {{pk}}, DATE_TRUNC('day', dms_utc_ts)
            ORDER BY dms_utc_ts DESC
        ) AS row_num_utc
    FROM
        {{source_schema}}.{{source_table}}
    {% if is_incremental() %}
        -- return all rows updated after the last time this model was run 
        WHERE dms_utc_ts > (select max(to_ts) from {{ this }})
    {% endif %}
),
-- If the row was deleted, then the to_ts is the timestamp of the delete
-- Otherwise, the to_ts is the timestamp of the next change
source as (
    SELECT
        *,
        dms_utc_ts as from_ts,
        CASE
            WHEN delta_operation = 'DELETE' THEN dms_utc_ts
            ELSE COALESCE(LEAD(dms_utc_ts::TIMESTAMP) OVER (PARTITION BY {{pk}} ORDER BY dms_utc_ts), '2050-01-01'::TIMESTAMP)
        END AS to_ts
    FROM
        ranked
)
-- SELECT
--     *
-- FROM
--     source
{% endmacro %}
