{% macro grant_select_schema (schemas, roles) %}
  {% for schema in schemas %}
    grant usage on schema {{ schema }} to role "{{ roles }}";
    grant select on all tables in schema {{ schema }} to role "{{ roles }}";
    alter default privileges in schema {{ schema }}
        grant select on tables to role "{{ roles }}";
  {% endfor %}
{% endmacro %}
