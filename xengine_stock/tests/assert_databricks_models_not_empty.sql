-- A build that produces zero rows is not a success. not_null / unique tests pass trivially on an empty table.
{{ config(enabled=(target.type == 'databricks'), tags=['cross_engine_producer_consumer', 'cross_engine', 'role_consumer', 'engine_databricks']) }}
select 'feat_exchange_monthly is empty' as problem where (select count(*) from {{ ref('feat_exchange_monthly') }}) = 0
