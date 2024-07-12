ALTER DATABASE datapai
  SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

USE datapai;

CREATE ROLE app_user;

CREATE LOGIN airbyte
 WITH PASSWORD = 'Welcome1$';
CREATE USER airbyte FOR LOGIN airbyte;
EXEC sp_addrolemember 'db_datareader', 'airbyte';
GO

EXEC sp_addrolemember 'app_user', 'airbyte';
GO
