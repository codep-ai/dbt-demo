

    SELECT playlist_id,
           playlist_name,
           track_id,
           track_name,
           artist_name,
           track_composer_name,
           track_milliseconds,
           track_bytes,
           album_title,
           genre_name,
           media_type_name
      FROM DATAPAI.DATAPAI.fct_playlist_track playlist_track
 LEFT JOIN DATAPAI.DATAPAI.stg_playlist track USING (playlist_id)