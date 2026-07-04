/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Staging (landing)
  Purpose : Bulk-load the Superstore source file into SuperstoreStaging.
  Input   : Superstore.csv  (9,994 data rows + 1 header row)
  Notes   : - The sample file ships in /sample-data (and /archive/Day 2/data).
            - Dates in the source are dd/mm/yyyy, so DATEFORMAT is set to dmy.
            - Update the FROM path to wherever you place the file locally.
==============================================================================*/

USE DW_Superstore;
GO

SET DATEFORMAT dmy;   -- source dates are dd/mm/yyyy
GO

TRUNCATE TABLE dbo.SuperstoreStaging;
GO

-- Comma-delimited CSV load (SQL Server 2017+ supports FORMAT = 'CSV').
-- FIELDQUOTE handles product names that contain embedded commas.
BULK INSERT dbo.SuperstoreStaging
FROM 'C:\Superstore.csv'
WITH (
    FORMAT        = 'CSV',
    FIRSTROW      = 2,        -- skip header
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',   -- \n
    TABLOCK
);
GO

-- Validation: this must return 9994.
SELECT COUNT(*) AS StagingRowCount FROM dbo.SuperstoreStaging;
GO
