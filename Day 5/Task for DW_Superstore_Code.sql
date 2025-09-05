--==================================================================================================
--
-- Automated script that creates DW_Superstore_Code
-- Based on Activity 2
--
-- INPUT  :	Flat file C:\Superstore.txt
-- OUTPUT :	Database DW_Superstore_Code
--
-- (c) 2020 masterofsql
--==================================================================================================

--==============================================================================
-- STEP #1: Creating new database and loading the staging table (the original dataset)
--==============================================================================
-- Create new database
SET NOCOUNT ON
USE master
GO
DROP DATABASE IF EXISTS DW_Superstore_Code
GO
CREATE DATABASE DW_Superstore_Code
GO
ALTER AUTHORIZATION ON DATABASE::DW_Superstore_Code TO SA
GO
USE DW_Superstore_Code
GO

-- Create staging table
CREATE TABLE SuperstoreStaging(
	Row_ID        BIGINT        NOT NULL,
	Order_ID      nvarchar(50)  NOT NULL,
	Order_Date    DATE          NOT NULL,
	Ship_Date     datetime2(7)  NOT NULL,
	Ship_Mode     VARCHAR(14)   NOT NULL,
	Customer_ID   CHAR(8)       NOT NULL,
	Customer_Name nvarchar(50)  NOT NULL,
	Segment       nvarchar(50)  NOT NULL,
	Country       nvarchar(50)  NOT NULL,
	City          VARCHAR(17)   NOT NULL,
	State         nvarchar(50)  NOT NULL,
	Postal_Code   CHAR(5)       NOT NULL,
	Region        nvarchar(50)  NOT NULL,
	Product_ID    CHAR(15)      NOT NULL,
	Category      nvarchar(50)  NOT NULL,
	Sub_Category  nvarchar(50)  NOT NULL,
	Product_Name  VARCHAR(127)  NOT NULL,
	Sales         FLOAT         NOT NULL,
	Quantity      INT           NOT NULL,
	Discount      FLOAT         NOT NULL,
	Profit        FLOAT         NOT NULL
)
GO

-- Load the original dataset
BULK INSERT SuperstoreStaging
FROM 'C:\\Superstore.txt'
WITH (FirstRow = 2, -- skip the header
      FieldTerminator = '\t',
      RowTerminator = '\n'
     )
GO

--==============================================================================
-- STEP #2: Creating dim tables
--==============================================================================
CREATE TABLE dimShipMode(
  ShipMode_SK BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  ShipMode    VARCHAR(14) NOT NULL
)
CREATE TABLE dimGeog(
  Geog_SK     BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  Country     CHAR(13)    NOT NULL,
  Region      VARCHAR(7)  NOT NULL,
  State       VARCHAR(20) NOT NULL,
  City        VARCHAR(17) NOT NULL,
  PostalCode  CHAR(5)     NOT NULL
)
CREATE TABLE dimProduct(
  Product_SK         BIGINT       NOT NULL IDENTITY(1,1) PRIMARY KEY,
  ProductId          CHAR(15)     NOT NULL,
  ProductName        VARCHAR(127) NOT NULL,
  ProductCategory    VARCHAR(15)  NOT NULL,
  ProductSubCategory VARCHAR(11)  NOT NULL
)
CREATE TABLE dimCustomer(
  Customer_SK     BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  CustomerId      CHAR(8)     NOT NULL,
  CustomerName    VARCHAR(22) NOT NULL,
  CustomerSegment VARCHAR(11) NOT NULL
)
CREATE TABLE dimDate(
  Date_SK   BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
  DateValue DATE   NOT NULL,
  [Day]     INT    NOT NULL,
  [Week]    INT    NOT NULL,
  [Month]   INT    NOT NULL,
  [Quarter] INT    NOT NULL,
  [Year]    INT    NOT NULL
)
GO

--==============================================================================
-- STEP #3: Populating dim tables
--==============================================================================
-- dimShipMode
INSERT INTO dimShipMode(ShipMode)
SELECT DISTINCT Ship_Mode 
FROM SuperstoreStaging
ORDER BY Ship_Mode

-- dimGeog
INSERT INTO dimGeog
SELECT DISTINCT Country, Region, State, City, Postal_Code
FROM SuperstoreStaging
ORDER BY Country, Postal_Code, City, State

-- dimProduct
INSERT INTO dimProduct
SELECT DISTINCT Product_ID, Product_Name, Category, Sub_Category
FROM SuperstoreStaging
ORDER BY Product_ID, Product_Name

-- dimCustomer
INSERT INTO dimCustomer(CustomerId, CustomerName, CustomerSegment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment
FROM SuperstoreStaging
ORDER BY Customer_ID, Customer_Name
GO

-- dimDate
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The following code MUST be executed as a single batch
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- declare variables to hold the start and end date
DECLARE @StartDate DATE
DECLARE @EndDate   DATE

-- assign values
SET @StartDate = '2014-01-01'
SET @EndDate   = '2017-12-31'

-- initialise loop variable
DECLARE @LoopDate DATE
SET @LoopDate = @StartDate

-- using a while loop,
-- increment from the start to the end date:
WHILE @LoopDate <= @EndDate
BEGIN
   -- add a record into the dimDate table for that particular date
   INSERT INTO dimDate(DateValue, [Day], [Week], [Month], [Quarter], [Year])
   VALUES (@LoopDate,
           DAY(@LoopDate),
           DATEPART(WEEK, @LoopDate),
           MONTH(@LoopDate),
           CASE WHEN Month(@LoopDate) IN (1, 2, 3)    THEN 1
                WHEN Month(@LoopDate) IN (4, 5, 6)    THEN 2
                WHEN Month(@LoopDate) IN (7, 8, 9)    THEN 3
                WHEN Month(@LoopDate) IN (10, 11, 12) THEN 4
           END,
           YEAR(@LoopDate)
          )
-- increment the LoopDate by 1 day,
-- and start another iteration for the next day
   SET @LoopDate = DATEADD(d, 1, @LoopDate)
END
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- End of the batch
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--==============================================================================
-- STEP #5: Creating and populating FACTs table
--==============================================================================
CREATE TABLE FACTOrderItem(
  Fact_SK      BIGINT       NOT NULL IDENTITY(1,1) PRIMARY KEY,
  Row_Id       BIGINT       NOT NULL,
  Order_Id     CHAR(14)     NOT NULL,
  Customer_SK  BIGINT       NOT NULL FOREIGN KEY REFERENCES dimCustomer(Customer_SK),
  Product_SK   BIGINT       NOT NULL FOREIGN KEY REFERENCES dimProduct(Product_SK),
  ShipMode_SK  BIGINT       NOT NULL FOREIGN KEY REFERENCES dimShipMode(ShipMode_SK),
  Geog_SK      BIGINT       NOT NULL FOREIGN KEY REFERENCES dimGeog(Geog_SK),
  OrderDate_SK BIGINT       NOT NULL FOREIGN KEY REFERENCES dimDate(Date_SK),
  ShipDate     DATE         NOT NULL,
  Sales        FLOAT        NOT NULL,
  Qty          INT          NOT NULL,
  Discount     DECIMAL(3,2) NOT NULL,
  Profit       FLOAT        NOT NULL
)
GO

INSERT INTO FACTOrderItem
SELECT DISTINCT
       Row_ID, Order_ID,
       c.Customer_SK,
       p.Product_SK,
       s.ShipMode_SK,
       g.Geog_SK,
       d.Date_SK,
       Ship_Date, Sales, Quantity, Discount, Profit
FROM SuperstoreStaging a
     JOIN dimCustomer  c ON a.Customer_ID = c.CustomerId
     JOIN dimProduct   p ON a.Product_ID  = p.ProductId  AND a.Product_Name = p.ProductName           
     JOIN dimShipMode  s ON a.Ship_Mode   = s.ShipMode
     JOIN dimGeog      g ON a.Postal_Code = g.PostalCode AND a.City = g.City
     JOIN dimDate      d ON a.Order_Date  = d.DateValue
ORDER BY Row_ID

-- DO NOT drop staging table as it will be used
-- to cross check Cubes that we will build

PRINT 'Done!'
SET NOCOUNT OFF
--==================================================================================================
-- DONE!
--==================================================================================================


IF OBJECT_ID('dbo.Cube1', 'V') IS NOT NULL
  DROP VIEW dbo.Cube1;
GO

CREATE VIEW dbo.Cube1
AS
SELECT
  c.Customer_SK,
  c.CustomerName,
  g.Region,
  g.State,
  g.City,
  d.[Year],
  d.Quarter,
  SUM(a.Qty)   AS Total_Qty,
  SUM(a.Sales) AS Total_Sales
FROM dbo.FACTOrderItem a
JOIN dbo.dimCustomer c ON a.Customer_SK = c.Customer_SK
JOIN dbo.dimGeog     g ON a.Geog_SK     = g.Geog_SK
JOIN dbo.dimDate     d ON a.OrderDate_SK = d.Date_SK
GROUP BY
  c.Customer_SK,
  c.CustomerName,
  g.Region,
  g.State,
  g.City,
  d.[Year],
  d.Quarter;
GO






-- ********************************* SQL DEMO *********************************
-- Build pie chart that shows sales across customer segments
-- ****************************************************************************
USE DW_Superstore_Code
GO

-- How big is our DW?
SELECT COUNT(*) FROM FACTOrderItem

-- List all the customer segments
SELECT DISTINCT CustomerSegment
FROM dimCustomer
ORDER BY CustomerSegment

-- List all the customer segments
SELECT DISTINCT CustomerSegment
FROM dimCustomer
ORDER BY CustomerSegment

-- Basic report on Customer Segment:
SELECT c.CustomerSegment,
       ROUND(SUM(Sales), 0) AS Total_Sales
FROM FACTOrderItem    a
     JOIN dimCustomer c ON a.Customer_SK = c.Customer_SK
GROUP BY c.CustomerSegment
ORDER BY Total_Sales DESC

-- (that belongs to a new CustomerSegment):
INSERT INTO dimCustomer(CustomerId, CustomerName, CustomerSegment)
VALUES('YY-007', 'James Bond', 'SecretAgent')



IF OBJECT_ID('dbo.vCustomerSegment', 'V') IS NOT NULL
  DROP VIEW dbo.vCustomerSegment;
GO

CREATE VIEW dbo.vCustomerSegment
AS
SELECT
  c.CustomerSegment,
  COALESCE(ROUND(SUM(a.Sales), 0), 0) AS Total_Sales
FROM dbo.dimCustomer c
LEFT JOIN dbo.FACTOrderItem a
  ON c.Customer_SK = a.Customer_SK
GROUP BY c.CustomerSegment;
GO

--ORDER BY Total_Sales DESC

SELECT *
FROM vCustomerSegment
ORDER BY Total_Sales DESC


-- Let's say your data now changes:
-- sales amount changes...
UPDATE FACTOrderItem
SET Sales = Sales * 100
WHERE Qty > 10


-- ...as well as another new segment appears:
INSERT INTO dimCustomer
VALUES('YY-008', 'Shrek', 'Hollywood')


--Query Folding
select [_].[CustomerName] as [Name],
    [_].[Region] as [Region],
    [_].[State] as [State],
    [_].[City] as [City],
    [_].[Quarter] as [Quarter],
    [_].[Total_Qty] as [Total_Qty],
    [_].[Total_Sales] as [Total_Sales]
from 
(
    select [CustomerName],
        [Region],
        [State],
        [City],
        [Quarter],
        [Total_Qty],
        [Total_Sales]
    from [dbo].[Cube1] as [$Table]
) as [_]
where [_].[Region] = 'South' or [_].[Region] = 'West'





-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- TASK 4 - Building Reporting Framework
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Questions are based on the database DW_Superstore_Code,
-- which was created in the previous activity

-- Produce SQL queries that answer the following questions:

-- A) Total sales for all the regions
-- B) Total sales across product categories
-- C) Yearly sales report across customer segments
-- D) Yearly total sales
-- E) Display top 5 months when sales were the highest


-- 'Sales' could be either SUM(Qty) or SUM(Sales), or both:
-- it does not matter - just be consistent

-- Guide time: 20 mins


-- However, here is the ultimate task:
-- F) Would you be able to answer ALL of the questions above in one view?
--    Create that view and call it MegaCube

-- Guide time: 25 mins


-- A) Total sales for all the regions (monetary + units)
SELECT
  g.Region,
  SUM(f.Sales) AS TotalSales
FROM FACTOrderItem f
JOIN dimGeog g ON f.Geog_SK = g.Geog_SK
GROUP BY g.Region
ORDER BY TotalSales DESC;


-- B) Total sales across product categories


SELECT
  p.ProductCategory,
  SUM(f.Sales) AS TotalSales
FROM FACTOrderItem f
JOIN dimProduct p ON f.Product_SK = p.Product_SK
GROUP BY p.ProductCategory
ORDER BY TotalSales DESC;


-- C) Yearly sales report across customer segments
SELECT
  d.[Year],
  c.CustomerSegment,
  SUM(f.Sales) AS TotalSales
FROM FACTOrderItem f
JOIN dimDate     d ON f.OrderDate_SK = d.Date_SK
JOIN dimCustomer c ON f.Customer_SK = c.Customer_SK
GROUP BY d.[Year], c.CustomerSegment
ORDER BY d.[Year], TotalSales DESC;




-- D

SELECT
  d.[Year],
  SUM(f.Sales) AS TotalSales
FROM FACTOrderItem f
JOIN dimDate d ON f.OrderDate_SK = d.Date_SK
GROUP BY d.[Year]
ORDER BY d.[Year];


-- E
SELECT TOP (5)
  d.[Year],
  d.[Month],
  SUM(f.Sales) AS TotalSales
FROM FACTOrderItem f
JOIN dimDate d ON f.OrderDate_SK = d.Date_SK
GROUP BY d.[Year], d.[Month]
ORDER BY TotalSales DESC;


-- F

-- Drop view if exists (optional)
IF OBJECT_ID('dbo.MegaCube', 'V') IS NOT NULL
  DROP VIEW dbo.MegaCube;
GO

CREATE VIEW dbo.MegaCube
AS
SELECT
  d.Date_SK,
  d.[Year],
  d.[Month],
  d.[Week],
  g.Geog_SK,
  g.Region,
  p.Product_SK,
  p.ProductCategory,
  p.ProductSubCategory,
  c.Customer_SK,
  c.CustomerSegment,
  SUM(f.Sales)   AS TotalSales,
  SUM(f.Qty)     AS TotalQty,
  SUM(f.Profit)  AS TotalProfit,
  AVG(CAST(f.Discount AS FLOAT)) AS AvgDiscount,
  COUNT(*)       AS TransactionCount
FROM FACTOrderItem f
JOIN dimDate     d ON f.OrderDate_SK = d.Date_SK
JOIN dimGeog     g ON f.Geog_SK = g.Geog_SK
JOIN dimProduct  p ON f.Product_SK = p.Product_SK
JOIN dimCustomer c ON f.Customer_SK = c.Customer_SK
GROUP BY
  d.Date_SK, d.[Year], d.[Month], d.[Week],
  g.Geog_SK, g.Region,
  p.Product_SK, p.ProductCategory, p.ProductSubCategory,
  c.Customer_SK, c.CustomerSegment;
GO
