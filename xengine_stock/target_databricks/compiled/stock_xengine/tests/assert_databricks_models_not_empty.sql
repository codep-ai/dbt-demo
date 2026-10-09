-- A build that produces zero rows is not a success. not_null / unique tests pass trivially on an empty table.

select 'feat_exchange_monthly is empty' as problem where (select count(*) from `azure_datapai_databricks_dev`.`stock_consumer_dbx`.`feat_exchange_monthly`) = 0
union all
select 'feat_price_momentum is empty' as problem where (select count(*) from `azure_datapai_databricks_dev`.`stock_consumer_dbx`.`feat_price_momentum`) = 0