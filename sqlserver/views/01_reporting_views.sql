/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Presentation / Reporting
  Purpose : Pre-aggregated "cube" views that BI tools (Power BI) consume.
  Notes   : These views encapsulate the star-join logic so report authors never
            join fact-to-dimension by hand. Naming preserved from the original
            project (Cube0-3, MegaCube, vCustomerSegment).
==============================================================================*/

USE DW_Superstore;
GO

DROP VIEW IF EXISTS dbo.MegaCube;
DROP VIEW IF EXISTS dbo.Cube0;
DROP VIEW IF EXISTS dbo.Cube1;
DROP VIEW IF EXISTS dbo.Cube2;
DROP VIEW IF EXISTS dbo.Cube3;
DROP VIEW IF EXISTS dbo.vCustomerSegment;
GO

--------------------------------------------------------------------------------
-- Cube0 : daily sales by calendar attributes.
--------------------------------------------------------------------------------
CREATE VIEW dbo.Cube0 AS
SELECT
    d.DateValue,
    d.[Day], d.[Week], d.[Month], d.[Quarter], d.[Year],
    SUM(f.Qty)   AS Total_Qty,
    SUM(f.Sales) AS Total_Sales
FROM dbo.FACTOrderItem AS f
    JOIN dbo.dimDate AS d ON f.OrderDate_SK = d.Date_SK
GROUP BY d.DateValue, d.[Day], d.[Week], d.[Month], d.[Quarter], d.[Year];
GO

--------------------------------------------------------------------------------
-- Cube1 : sales by customer, geography and quarter.
--------------------------------------------------------------------------------
CREATE VIEW dbo.Cube1 AS
SELECT
    c.Customer_SK, c.CustomerName,
    g.Region, g.State, g.City,
    d.[Year], d.[Quarter],
    SUM(f.Qty)   AS Total_Qty,
    SUM(f.Sales) AS Total_Sales
FROM dbo.FACTOrderItem AS f
    JOIN dbo.dimCustomer AS c ON f.Customer_SK  = c.Customer_SK
    JOIN dbo.dimGeog     AS g ON f.Geog_SK      = g.Geog_SK
    JOIN dbo.dimDate     AS d ON f.OrderDate_SK = d.Date_SK
GROUP BY c.Customer_SK, c.CustomerName, g.Region, g.State, g.City, d.[Year], d.[Quarter];
GO

--------------------------------------------------------------------------------
-- Cube2 : weekly sales by product category, customer segment and region.
--------------------------------------------------------------------------------
CREATE VIEW dbo.Cube2 AS
SELECT
    d.[Year], d.[Week],
    p.ProductCategory,
    c.CustomerSegment,
    g.Region,
    SUM(f.Qty)   AS Total_Qty,
    SUM(f.Sales) AS Total_Sales
FROM dbo.FACTOrderItem AS f
    JOIN dbo.dimDate     AS d ON f.OrderDate_SK = d.Date_SK
    JOIN dbo.dimProduct  AS p ON f.Product_SK   = p.Product_SK
    JOIN dbo.dimCustomer AS c ON f.Customer_SK  = c.Customer_SK
    JOIN dbo.dimGeog     AS g ON f.Geog_SK      = g.Geog_SK
GROUP BY d.[Year], d.[Week], p.ProductCategory, c.CustomerSegment, g.Region;
GO

--------------------------------------------------------------------------------
-- Cube3 : yearly sales by product category.
--------------------------------------------------------------------------------
CREATE VIEW dbo.Cube3 AS
SELECT
    p.ProductCategory,
    d.[Year],
    SUM(f.Qty)   AS Total_Qty,
    SUM(f.Sales) AS Total_Sales
FROM dbo.FACTOrderItem AS f
    JOIN dbo.dimProduct AS p ON f.Product_SK   = p.Product_SK
    JOIN dbo.dimDate    AS d ON f.OrderDate_SK = d.Date_SK
GROUP BY p.ProductCategory, d.[Year];
GO

--------------------------------------------------------------------------------
-- vCustomerSegment : total sales per customer segment (LEFT JOIN keeps segments
--                    with no orders, defaulted to 0).
--------------------------------------------------------------------------------
CREATE VIEW dbo.vCustomerSegment AS
SELECT
    c.CustomerSegment,
    COALESCE(ROUND(SUM(f.Sales), 0), 0) AS Total_Sales
FROM dbo.dimCustomer AS c
    LEFT JOIN dbo.FACTOrderItem AS f ON c.Customer_SK = f.Customer_SK
GROUP BY c.CustomerSegment;
GO

--------------------------------------------------------------------------------
-- MegaCube : the "answer everything" grain-rich view that supports slicing by
--            date, geography, product and customer in a single object.
--------------------------------------------------------------------------------
CREATE VIEW dbo.MegaCube AS
SELECT
    d.Date_SK, d.[Year], d.[Month], d.[Week],
    g.Geog_SK, g.Region,
    p.Product_SK, p.ProductCategory, p.ProductSubCategory,
    c.Customer_SK, c.CustomerSegment,
    SUM(f.Sales)                    AS TotalSales,
    SUM(f.Qty)                      AS TotalQty,
    SUM(f.Profit)                   AS TotalProfit,
    AVG(CAST(f.Discount AS FLOAT))  AS AvgDiscount,
    COUNT(*)                        AS TransactionCount
FROM dbo.FACTOrderItem AS f
    JOIN dbo.dimDate     AS d ON f.OrderDate_SK = d.Date_SK
    JOIN dbo.dimGeog     AS g ON f.Geog_SK      = g.Geog_SK
    JOIN dbo.dimProduct  AS p ON f.Product_SK   = p.Product_SK
    JOIN dbo.dimCustomer AS c ON f.Customer_SK  = c.Customer_SK
GROUP BY
    d.Date_SK, d.[Year], d.[Month], d.[Week],
    g.Geog_SK, g.Region,
    p.Product_SK, p.ProductCategory, p.ProductSubCategory,
    c.Customer_SK, c.CustomerSegment;
GO

PRINT 'Reporting views created.';
GO
