{{ config(materialized="view", tags="staging") }}

SELECT * FROM {{ ref('playlisttrack') }}
