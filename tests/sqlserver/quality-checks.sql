/*==============================================================================
  Superstore DW  |  SQL Server  |  Tests: Data-quality checks
  Purpose : Duplicate detection, NULL checks, referential integrity, and
            fact-to-dimension orphan detection. Every query should return ZERO
            rows for a healthy warehouse.
  Usage   : Run against DW_Superstore. Any non-empty result = a data-quality issue.
==============================================================================*/
USE DW_Superstore;
GO
SET NOCOUNT ON;

--------------------------------------------------------------------------------
PRINT '=== 1. Duplicate natural keys in dimensions (expect 0 rows each) ===';
--------------------------------------------------------------------------------
SELECT 'dimCustomer dup CustomerId' AS Check_Name, CustomerId, COUNT(*) AS Cnt
FROM dbo.dimCustomer GROUP BY CustomerId HAVING COUNT(*) > 1;

SELECT 'dimProduct dup ProductId+Name' AS Check_Name, ProductId, ProductName, COUNT(*) AS Cnt
FROM dbo.dimProduct GROUP BY ProductId, ProductName HAVING COUNT(*) > 1;

SELECT 'dimShipMode dup ShipMode' AS Check_Name, ShipMode, COUNT(*) AS Cnt
FROM dbo.dimShipMode GROUP BY ShipMode HAVING COUNT(*) > 1;

SELECT 'dimDate dup DateValue' AS Check_Name, DateValue, COUNT(*) AS Cnt
FROM dbo.dimDate GROUP BY DateValue HAVING COUNT(*) > 1;

--------------------------------------------------------------------------------
PRINT '=== 2. NULLs in fact key columns (expect 0) ===';
--------------------------------------------------------------------------------
SELECT COUNT(*) AS NullKeyRows
FROM dbo.FACTOrderItem
WHERE Customer_SK IS NULL OR Product_SK IS NULL OR ShipMode_SK IS NULL
   OR Geog_SK IS NULL OR OrderDate_SK IS NULL;

--------------------------------------------------------------------------------
PRINT '=== 3. Fact-to-dimension referential integrity / orphans (expect 0 rows each) ===';
--------------------------------------------------------------------------------
SELECT 'Orphan Customer_SK' AS Check_Name, f.Fact_SK
FROM dbo.FACTOrderItem f LEFT JOIN dbo.dimCustomer d ON f.Customer_SK = d.Customer_SK
WHERE d.Customer_SK IS NULL;

SELECT 'Orphan Product_SK' AS Check_Name, f.Fact_SK
FROM dbo.FACTOrderItem f LEFT JOIN dbo.dimProduct d ON f.Product_SK = d.Product_SK
WHERE d.Product_SK IS NULL;

SELECT 'Orphan Geog_SK' AS Check_Name, f.Fact_SK
FROM dbo.FACTOrderItem f LEFT JOIN dbo.dimGeog d ON f.Geog_SK = d.Geog_SK
WHERE d.Geog_SK IS NULL;

SELECT 'Orphan ShipMode_SK' AS Check_Name, f.Fact_SK
FROM dbo.FACTOrderItem f LEFT JOIN dbo.dimShipMode d ON f.ShipMode_SK = d.ShipMode_SK
WHERE d.ShipMode_SK IS NULL;

SELECT 'Orphan OrderDate_SK' AS Check_Name, f.Fact_SK
FROM dbo.FACTOrderItem f LEFT JOIN dbo.dimDate d ON f.OrderDate_SK = d.Date_SK
WHERE d.Date_SK IS NULL;

--------------------------------------------------------------------------------
PRINT '=== 4. Business-rule sanity (expect 0 rows) ===';
--------------------------------------------------------------------------------
-- Ship date should never precede order date.
SELECT 'ShipDate < OrderDate' AS Check_Name, f.Fact_SK, d.DateValue AS OrderDate, f.ShipDate
FROM dbo.FACTOrderItem f JOIN dbo.dimDate d ON f.OrderDate_SK = d.Date_SK
WHERE f.ShipDate < d.DateValue;

-- Quantity should be positive.
SELECT 'Non-positive Qty' AS Check_Name, Fact_SK, Qty FROM dbo.FACTOrderItem WHERE Qty <= 0;

-- Discount must be a valid rate between 0 and 1.
SELECT 'Discount out of range' AS Check_Name, Fact_SK, Discount
FROM dbo.FACTOrderItem WHERE Discount < 0 OR Discount > 1;

--------------------------------------------------------------------------------
PRINT '=== 5. Constraint / metadata verification ===';
--------------------------------------------------------------------------------
-- List foreign keys and whether any are untrusted (not verified).
SELECT
    fk.name AS ForeignKey,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.is_not_trusted AS IsNotTrusted   -- 0 = trusted/verified (good)
FROM sys.foreign_keys fk
WHERE fk.parent_object_id = OBJECT_ID('dbo.FACTOrderItem');
GO
