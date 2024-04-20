{% {% macro print_multi_tables() %}

    {% set tables = ['table_1', 'table_2', 'table_3', 'table_4', 'table_5'] %}
    {% set ns = namespace(query_results = [], final_result = '[') %}
    {% set query_results = [] %}

    {% for table_name in tables %}

        {% set query %}
            select count(*) from {{ ref(table_name) }} where students = 'great'
        {% endset %}
        {{ log(query, true) }}

        {% set results = run_query(query) %}
        {% set count = results.rows[0][0] %}
        {% set query_results = query_results.append(count) %}

    {% endfor %}

    {# This gives a result like [Decimal('2'), Decimal('8')], so #}
    {# there is more code below to print the exact results you want #}
    {{ log(query_results, true) }}

    {# Print the results in the format [result_1, result_2, etc] #}
    {% for x in query_results %}
        {% set ns.final_result = ns.final_result ~ x %}
        {% if not loop.last %}
            {% set ns.final_result = ns.final_result ~ ', ' %}
        {% endif %}
    {% endfor %}
    {% set ns.final_result = ns.final_result ~ ']' %}
    {{ log(ns.final_result, true) }}

{% endmacro %}
