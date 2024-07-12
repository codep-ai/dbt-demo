USE datapai;
GO
EXEC sys.sp_cdc_enable_db
GO



EXEC sys.sp_cdc_enable_table
@capture_instance = 'sales_store_cdc',
@source_schema = N'sales',
@source_name   = N'stores',
@role_name     = N'app_user' ,
@filegroup_name = NULL,
@supports_net_changes = 0
GO
