{{ config(materialized="view", tags="staging") }}

SELECT artist_id,
       name AS artist_name
  FROM {{ ref('artist') }}
