
ALTER SERVER ROLE sysadmin ADD MEMBER airbyte; -- Replace [your_user] with the username
GO

USE datapai
GO

EXEC sys.sp_cdc_start_job;
GO
/*

EXEC sp_cdc_change_job @job_type='cleanup', @retention = 14400

GO


EXEC sys.sp_cdc_stop_job @job_type = 'cleanup';

EXEC sys.sp_cdc_start_job @job_type = 'cleanup';

GO

EXEC xp_servicecontrol 'QueryState', N'SQLServerAGENT';

GO
*/
