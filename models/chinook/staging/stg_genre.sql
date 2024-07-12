{{ config(materialized="view", tags="staging") }}

SELECT genre_id,
       name AS genre_name
  FROM {{ ref('genre') }}
