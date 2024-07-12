{% macro snowflake_date_parts(date_key) %}
    SELECT
        DATE_PART('dayofyear', {{ date_key }}) AS day_of_year,
        DATE_PART('week', {{ date_key }}) AS week_key,
        DATE_PART('weekofyear', {{ date_key }}) AS week_of_year,
        DATE_PART('dayofweek', {{ date_key }}) AS day_of_week,
        TO_NUMBER(TO_VARCHAR({{ date_key }}, 'ID')) AS iso_day_of_week,
        DAYNAME({{ date_key }}) AS day_name,
        DATE_TRUNC('week', {{ date_key }}) AS first_day_of_week,
        DATEADD('DAY', 6, DATE_TRUNC('week', {{ date_key }})) AS last_day_of_week,
        TO_VARCHAR(YEAR({{ date_key }}), 'YYYYMM') AS month_key,
        MONTH({{ date_key }}) AS month_of_year,
        DAYOFMONTH({{ date_key }}) AS day_of_month,
        LEFT(TO_VARCHAR({{ date_key }}, 'Month'), 3) AS month_name_short,
        TO_VARCHAR({{ date_key }}, 'Month') AS month_name,
        DATE_TRUNC('month', {{ date_key }}) AS first_day_of_month,
        LAST_DAY({{ date_key }}) AS last_day_of_month,
        QUARTER({{ date_key }}) AS quarter_of_year,
        DATEDIFF('day', DATE_TRUNC('quarter', {{ date_key }}), {{ date_key }}) + 1 AS day_of_quarter,
        'Q' || TO_VARCHAR(QUARTER({{ date_key }})) AS quarter_desc_short,
        'Quarter ' || TO_VARCHAR(QUARTER({{ date_key }})) AS quarter_desc,
        DATE_TRUNC('quarter', {{ date_key }}) AS first_day_of_quarter,
        LAST_DAY(DATEADD('MONTH', 2, DATE_TRUNC('quarter', {{ date_key }}))) AS last_day_of_quarter,
        YEAR({{ date_key }}) AS year_key,
        DATE_TRUNC('year', {{ date_key }}) AS first_day_of_year,
        DATEADD('YEAR', 1, DATE_TRUNC('year', {{ date_key }})) - 1 AS last_day_of_year
{% endmacro %}

