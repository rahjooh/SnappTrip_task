{#
  Use only the custom schema (e.g. silver, gold) for the local Iceberg target.
  Default dbt behavior would produce default_silver / default_gold, but our
  tables live in catalog "local" with schema "silver" or "gold".
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- set default_schema = target.schema -%}
  {%- if target.name in ('local', 'local_docker') and custom_schema_name is not none -%}
    {{ custom_schema_name | trim }}
  {%- elif custom_schema_name is none -%}
    {{ default_schema }}
  {%- else -%}
    {{ default_schema }}_{{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
