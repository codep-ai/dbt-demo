{% macro cast_to_timestamp(date_in_string_format, timezone_format_destination='utc', timezone_format_source='utc') %}
         CASE
            WHEN SUBSTRING( {{ date_in_string_format }}, 21, 6 ) = '999999'
               THEN (SUBSTRING( {{date_in_string_format }}, 1, 19 ) || '.' || '999999')::timestamp
            ELSE {{ date_in_string_format }}::timestamp AT TIME ZONE '{{ timezone_format_source }}' AT TIME ZONE '{{ timezone_format_destination }}'
         END
{% endmacro %}