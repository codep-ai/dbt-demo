

    SELECT *
      FROM DATAPAI.DATAPAI.stg_playlist_track playlist_track
 LEFT JOIN DATAPAI.DATAPAI.dim_track track USING (track_id)