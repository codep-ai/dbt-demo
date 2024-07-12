




select
  'dbt_models' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_models
 union all 

select
  'dbt_tests' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_tests
 union all 

select
  'dbt_sources' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_sources
 union all 

select
  'dbt_snapshots' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_snapshots
 union all 

select
  'dbt_metrics' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_metrics
 union all 

select
  'dbt_exposures' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_exposures
 union all 

select
  'dbt_seeds' as artifacts_model,
   metadata_hash
from DATAPAI.DATAPAI_audit.dbt_seeds


order by metadata_hash