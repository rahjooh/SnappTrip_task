{#
  Use only the custom schema (e.g. silver, gold) so tables live in
  catalog "local" with schema "silver" or "gold", not default_silver.
  Applies to all targets so run and test always resolve the same relation.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- set default_schema = target.schema -%}
  {%- if custom_schema_name is not none -%}
    {{ custom_schema_name | trim }}
  {%- elif custom_schema_name is none -%}
    {{ default_schema }}
  {%- else -%}
    {{ default_schema }}_{{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
