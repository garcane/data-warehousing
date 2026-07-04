/*==============================================================================
  Superstore DW  |  SQL Server  |  Tests: Row-count & structural validation
  Purpose : Confirm the build produced the expected shape. Each check prints
            PASS/FAIL so it can be eyeballed or captured by CI.
  Usage   : Run against DW_Superstore after the full build.
==============================================================================*/
USE DW_Superstore;
GO
SET NOCOUNT ON;

PRINT '=== Row-count validation (expected baseline) ===';

;WITH counts AS (
    SELECT 'SuperstoreStaging' AS ObjectName, COUNT(*) AS ActualRows, 9994 AS ExpectedRows FROM dbo.SuperstoreStaging
    UNION ALL SELECT 'dimShipMode',  COUNT(*), 4    FROM dbo.dimShipMode
    UNION ALL SELECT 'dimGeog',      COUNT(*), 632  FROM dbo.dimGeog
    UNION ALL SELECT 'dimProduct',   COUNT(*), 1894 FROM dbo.dimProduct
    UNION ALL SELECT 'dimCustomer',  COUNT(*), 794  FROM dbo.dimCustomer
    UNION ALL SELECT 'dimDate',      COUNT(*), 1458 FROM dbo.dimDate
    UNION ALL SELECT 'FACTOrderItem',COUNT(*), 9994 FROM dbo.FACTOrderItem
)
SELECT
    ObjectName,
    ExpectedRows,
    ActualRows,
    CASE WHEN ActualRows = ExpectedRows THEN 'PASS' ELSE 'FAIL' END AS Result
FROM counts
ORDER BY ObjectName;
GO

PRINT '=== Fact row count must equal staging row count (no rows lost/duplicated in ETL) ===';
SELECT
    (SELECT COUNT(*) FROM dbo.SuperstoreStaging) AS StagingRows,
    (SELECT COUNT(*) FROM dbo.FACTOrderItem)     AS FactRows,
    CASE WHEN (SELECT COUNT(*) FROM dbo.SuperstoreStaging) = (SELECT COUNT(*) FROM dbo.FACTOrderItem)
         THEN 'PASS' ELSE 'FAIL' END AS Result;
GO

PRINT '=== Measure totals reconcile staging vs fact (ETL preserved the numbers) ===';
SELECT
    CAST((SELECT SUM(Sales) FROM dbo.SuperstoreStaging) AS DECIMAL(18,2)) AS StagingSales,
    CAST((SELECT SUM(Sales) FROM dbo.FACTOrderItem)     AS DECIMAL(18,2)) AS FactSales,
    CASE WHEN ROUND((SELECT SUM(Sales) FROM dbo.SuperstoreStaging),2)
            = ROUND((SELECT SUM(Sales) FROM dbo.FACTOrderItem),2)
         THEN 'PASS' ELSE 'FAIL' END AS Result;
GO
