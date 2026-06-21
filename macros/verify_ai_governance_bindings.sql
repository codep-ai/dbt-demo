{# verify_ai_governance_bindings — runs every AI-governance binding's
   evidence_query against the current warehouse. Returns success only if
   every evidence_query returns zero rows. Invoked by the CI merge workflow
   (.github/workflows/dbt-merge.yml) and runnable locally as:

       dbt run-operation verify_ai_governance_bindings

   The bindings are loaded from seeds/ai_mart/ai_control_bindings_seed.csv
   via {{ ref('ai_control_bindings_seed') }}. Each row's evidence_query is
   a templated SQL fragment; the macro renders it (so {{ ref('...') }} inside
   the query resolves), executes it, and aggregates a single row per
   binding into the log.

   failure_mode:
     - 'block'      → non-zero result raises an error (fails the dbt run)
     - 'warn_only'  → non-zero result logs a warning; build continues
   See docs/AI_GOVERNANCE_BINDING.md for the pilot-stage default.
#}

{% macro verify_ai_governance_bindings() %}

    {% if execute %}

        {% set bindings_query %}
            select
                model_name,
                control_id,
                binding_type,
                evidence_query,
                failure_mode
            from {{ ref('ai_control_bindings_seed') }}
            where coalesce(failure_mode, 'warn_only') in ('warn_only', 'block')
        {% endset %}

        {% set bindings = run_query(bindings_query) %}

        {% set total = bindings.rows | length %}
        {% set failures = [] %}
        {% set warnings = [] %}

        {{ log("verify_ai_governance_bindings: " ~ total ~ " bindings to check", info=True) }}

        {% for row in bindings.rows %}
            {% set model_name = row[0] %}
            {% set control_id = row[1] %}
            {% set binding_type = row[2] %}
            {% set evidence_sql = row[3] %}
            {% set failure_mode = row[4] or 'warn_only' %}

            {# Render the evidence query so any ref()/source() inside it resolve. #}
            {% set rendered_sql %}
                {{ evidence_sql }}
            {% endset %}

            {% set result = run_query(rendered_sql) %}
            {% set violation_count = result.rows[0][0] if result and result.rows else 0 %}

            {% if violation_count and violation_count > 0 %}
                {% set msg = "BINDING VIOLATED — model=" ~ model_name ~ " control=" ~ control_id
                             ~ " type=" ~ binding_type ~ " rows=" ~ violation_count %}
                {% if failure_mode == 'block' %}
                    {% do failures.append(msg) %}
                    {{ log("FAIL  · " ~ msg, info=True) }}
                {% else %}
                    {% do warnings.append(msg) %}
                    {{ log("WARN  · " ~ msg, info=True) }}
                {% endif %}
            {% else %}
                {{ log("OK    · " ~ model_name ~ "/" ~ control_id, info=True) }}
            {% endif %}
        {% endfor %}

        {{ log("verify_ai_governance_bindings: " ~ (total - failures|length - warnings|length)
               ~ " ok, " ~ warnings|length ~ " warn, " ~ failures|length ~ " fail", info=True) }}

        {% if failures|length > 0 %}
            {{ exceptions.raise_compiler_error(
                "AI governance bindings violated (failure_mode=block):\n" ~ failures | join("\n")
            ) }}
        {% endif %}

    {% endif %}

{% endmacro %}
