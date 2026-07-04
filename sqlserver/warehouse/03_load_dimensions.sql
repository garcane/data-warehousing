/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (dimension load)
  Purpose : Populate the master dimensions from the staging table.
  Method  : Set-based INSERT ... SELECT DISTINCT (idempotent via TRUNCATE).
  Expected row counts: dimShipMode = 4, dimGeog = 632,
                       dimProduct = 1894, dimCustomer = 794.
==============================================================================*/

USE DW_Superstore;
GO

-- Reset dimensions (fact is truncated first because of the FKs).
DELETE FROM dbo.FACTOrderItem;
TRUNCATE TABLE dbo.dimShipMode;
TRUNCATE TABLE dbo.dimGeog;
TRUNCATE TABLE dbo.dimProduct;
TRUNCATE TABLE dbo.dimCustomer;
GO

-- dimShipMode
INSERT INTO dbo.dimShipMode (ShipMode)
SELECT DISTINCT Ship_Mode
FROM dbo.SuperstoreStaging
ORDER BY Ship_Mode;

-- dimGeog
INSERT INTO dbo.dimGeog (Country, Region, State, City, PostalCode)
SELECT DISTINCT Country, Region, State, City, Postal_Code
FROM dbo.SuperstoreStaging
ORDER BY Country, Postal_Code, City, State;

-- dimProduct
INSERT INTO dbo.dimProduct (ProductId, ProductName, ProductCategory, ProductSubCategory)
SELECT DISTINCT Product_ID, Product_Name, Category, Sub_Category
FROM dbo.SuperstoreStaging
ORDER BY Product_ID, Product_Name;

-- dimCustomer  (Segment denormalised into the customer dimension - by design)
INSERT INTO dbo.dimCustomer (CustomerId, CustomerName, CustomerSegment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment
FROM dbo.SuperstoreStaging
ORDER BY Customer_ID, Customer_Name;
GO

PRINT 'Dimensions loaded.';
GO
