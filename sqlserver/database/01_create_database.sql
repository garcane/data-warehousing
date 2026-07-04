/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server  |  Reference implementation
  Layer   : Database
  Purpose : Create the DW_Superstore database (idempotent).
  Notes   : This is the canonical, cleaned version of the automated build script
            originally developed in the learning journal (see /archive).
  Run as  : A login with permission to CREATE DATABASE (e.g. sysadmin).
==============================================================================*/

USE master;
GO

-- Drop-and-recreate keeps the build fully idempotent for CI / demos.
IF DB_ID(N'DW_Superstore') IS NOT NULL
BEGIN
    ALTER DATABASE DW_Superstore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_Superstore;
END
GO

CREATE DATABASE DW_Superstore;
GO

-- SIMPLE recovery is appropriate for an analytical/reporting store that is
-- rebuilt from source, not point-in-time recovered.
ALTER DATABASE DW_Superstore SET RECOVERY SIMPLE;
GO

PRINT 'Database DW_Superstore created.';
GO
