{{ config(
    materialized="table",
    tags=["dim"]
) }}

WITH RECURSIVE generate_date AS (
    SELECT DATE '2009-01-01' AS date_key
    UNION ALL
    SELECT DATEADD(DAY, 1, date_key)
    FROM generate_date
    WHERE date_key <= DATE '2013-12-31'
)
SELECT
    date_key AS date_key,
    DAYOFYEAR(date_key) AS day_of_year,
    DATE_PART('week', date_key) AS week_key,
    DAYOFWEEK(date_key) AS day_of_week,
    MONTH(date_key) AS month_of_year,
    DAYOFMONTH(date_key) AS day_of_month,
    QUARTER(date_key) AS quarter_of_year,
    YEAR(date_key) AS year_key,
    ROW_NUMBER() OVER (PARTITION BY YEAR(date_key), MONTH(date_key), DAYOFWEEK(date_key) ORDER BY date_key) AS ordinal_weekday_of_month
FROM generate_date

