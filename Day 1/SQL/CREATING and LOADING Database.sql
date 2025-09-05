--==============================================================================
-- STEP #1: Create new database and load the original dataset
--==============================================================================
USE master
GO
DROP DATABASE IF EXISTS DW_Sales
GO
CREATE DATABASE DW_Sales
GO
USE DW_Sales
GO



-- rename the table
EXEC sp_rename 'Sales', 'StagingSales'

-- Preview the table
 SELECT    * FROM StagingSales
SELECT TOP 5 * FROM StagingSales


-- This query must return 744 records:
SELECT COUNT(*) FROM StagingSales


--==============================================================================
-- STEP #2: Create and populate dim (dimension) tables from the staging table
--==============================================================================

USE DW_Sales
GO

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Investigate salesChannel field:
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get distinct values from this field:
SELECT DISTINCT salesChannel
FROM StagingSales
ORDER BY salesChannel 


-- Find out the maximum length of salesChannel field...
SELECT MAX(LEN(salesChannel)) FROM StagingSales

-- ...and finally create the new table for this dimension:
DROP TABLE IF EXISTS SalesChannel
GO
CREATE TABLE SalesChannel(
  Channel_SK  BIGINT     NOT NULL IDENTITY(1,1) PRIMARY KEY,
  ChannelName VARCHAR(6) NOT NULL
)
GO

SELECT * 
FROM SalesChannel

-- Populate table SalesChannel
INSERT INTO SalesChannel(ChannelName)
SELECT DISTINCT salesChannel 
FROM StagingSales
ORDER BY salesChannel



------------------------------------------------------------
-- TASK 1
------------------------------------------------------------
-- Repeat the same steps for four more dim tables:
-- Region, Customer, Product, Country
--
-- Total number of fields in each table (including PK/SK):
-- Region: 2, Customer: 2, Product: 4, Country: 3
--
-- Number of records you should get:
-- Region: 8, Customer: 744, Product: 9, Country: 150
--
-- Notes to take into account
-- 1. Start with the table Region as it is the easiest one -
--    just follow the example of SalesChannel
-- 2. Do not create Surrogate Key for Customer, use the existing one
-- 3. Do not create Surrogate Key for Product,  use the existing one
-- 4. Table Country should reference RegionName by its id (Region_SK)


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Investigate Regionfield:
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get distinct values from this field:
SELECT DISTINCT Region
FROM StagingSales
ORDER BY Region

-- Find out the maximum length of salesChannel field...
SELECT MAX(LEN(Region)) FROM StagingSales


-- Create dimension table Region
-- (but drop all the dependent tables first)
--DROP TABLE IF EXISTS Country
--GO
--DROP TABLE IF EXISTS Region
--GO
CREATE TABLE Region(
  Region_SK  BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  RegionName VARCHAR(33) NOT NULL
)
GO

-- Populate table Region
INSERT INTO Region(RegionName)
SELECT DISTINCT Region
FROM StagingSales
ORDER BY Region

SELECT * 
FROM Region

SELECT * 
FROM StagingSales





-- ProductSold vs ProductId?
SELECT *
FROM StagingSales
WHERE productSold != productId

SELECT DISTINCT(CAST(DateSold AS DATE)) FROM StagingSales




-- Create FACTs table
DROP TABLE IF EXISTS Sale
GO
CREATE TABLE Sale(
  FACT_SK    BIGINT  NOT NULL IDENTITY(1,1) PRIMARY KEY,
  RowId      BIGINT  NOT NULL,
  DateSold   DATE    NOT NULL,
  UnitsSold  INT     NOT NULL,

  Channel_SK BIGINT  NOT NULL,
  CustomerId BIGINT  NOT NULL,
  ProductId  CHAR(7) NOT NULL,
  Country_SK BIGINT  NOT NULL
)
GO



-- Create FACTs table
DROP TABLE IF EXISTS Sale
GO
CREATE TABLE Sale(
  FACT_SK    BIGINT  NOT NULL IDENTITY(1,1) PRIMARY KEY,
  RowId      BIGINT  NOT NULL,
  DateSold   DATE    NOT NULL,
  UnitsSold  INT     NOT NULL,

  Channel_SK BIGINT  NOT NULL,
  CustomerId BIGINT  NOT NULL,
  ProductId  CHAR(7) NOT NULL,
  Country_SK BIGINT  NOT NULL
)
GO


SELECT s.RowId,
    s.dateSold, 
    s.unitsSold, 
    a.Channel_SK,
    s.custId,
    s.productId,
    c.Country_SK
FROM StagingSales s
JOIN SalesChannel a ON s.salesChannel = a.ChannelName
JOIN Country      c ON s.Country = c.CountryName
ORDER BY s.dateSold, s.RowId



-- to show that these are our dimensions...
EXEC sp_rename 'SalesChannel', 'dimSalesChannel'
EXEC sp_rename 'Customer',     'dimCustomer'
EXEC sp_rename 'Product',      'dimProduct'
EXEC sp_rename 'Region',       'dimRegion'
EXEC sp_rename 'Country',      'dimCountry'



EXEC sp_rename 'Sale',         'FACTSale'






-- Add foreign keys
ALTER TABLE FACTSale ADD FOREIGN KEY (CustomerId) REFERENCES dimCustomer(CustomerId)
ALTER TABLE FACTSale ADD FOREIGN KEY (ProductId)  REFERENCES dimProduct(ProductId)
ALTER TABLE FACTSale ADD FOREIGN KEY (Channel_SK) REFERENCES dimSalesChannel(Channel_SK)
ALTER TABLE FACTSale ADD FOREIGN KEY (Country_SK) REFERENCES dimCountry(Country_SK)



ALTER AUTHORIZATION ON DATABASE::DW_Sales TO SA

