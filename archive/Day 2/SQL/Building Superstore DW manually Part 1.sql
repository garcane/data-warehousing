--==============================================================================
-- STEP #1: Create new database,
--          and load the original dataset into the staging table
--==============================================================================
-- Create new database
USE master
GO
DROP DATABASE IF EXISTS DW_Superstore_Manual
GO
CREATE DATABASE DW_Superstore_Manual
GO
ALTER AUTHORIZATION ON DATABASE::DW_Superstore_Manual TO SA
GO
USE DW_Superstore_Manual
GO

-- BULK INSERT requires table to be created
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




-- How to Check Database Owner?
SELECT name AS DW_Superstore_Manual, SUSER_SNAME(owner_sid) AS Owner
FROM sys.databases;






-- BULK INSERT command for this input file
-- requires a bit of tweaking:
-- Set proper date format...
SET DATEFORMAT dmy
GO






-- ...and load the dataset
BULK INSERT SuperstoreStaging
FROM 'C:\\Superstore.csv'
WITH (Format = 'CSV', -- MS SQL 2017+ only
      RowTerminator = '\n',
      FirstRow = 2
     )
GO








-- Check that all the records have been imported (should be 9994):
SELECT COUNT(*) FROM SuperstoreStaging
-- Preview the imported dataset:
SELECT TOP 10 * FROM SuperstoreStaging








--==============================================================================
-- STEP #2: Create dim tables
--==============================================================================
USE DW_Superstore_Manual
GO

-- Drop all the dim tables first
DROP TABLE IF EXISTS FACTOrderItem
DROP TABLE IF EXISTS dimShipMode
DROP TABLE IF EXISTS dimGeog
DROP TABLE IF EXISTS dimProduct
DROP TABLE IF EXISTS dimCustomer
GO








------------------------------------------------------------
-- TASK 1
------------------------------------------------------------
-- Attempt to build the following dim tables:
-- dimShipMode, dimGeog (Geography), dimProduct, dimCustomer
--
-- No need to populate tables at this stage - we'll do it later
--
-- Hints
-- Create Surrogate Key for every table
-- Table dimCustomer must contain Segment field (yes, this is against 3NF)
--
-- Total number of fields in these tables should be:
-- dimShipMode: 2, dimGeog: 6, dimProduct: 5, dimCustomer: 4
-- (these numbers include SK fields)
--



--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- dimShipMode
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT DISTINCT Ship_Mode
FROM SuperstoreStaging

SELECT MAX(LEN(Ship_Mode)) FROM SuperstoreStaging


CREATE TABLE dimShipMode(
  ShipMode_SK BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  ShipMode    VARCHAR(14) NOT NULL
)
GO
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~






--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- dimGeog
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT DISTINCT Country, City, State, Postal_Code, Region
FROM SuperstoreStaging


-- Which 5 fields did you select for this table?

SELECT MIN(LEN(Country)),     MAX(LEN(Country))     FROM SuperstoreStaging
SELECT MIN(LEN(Region)),      MAX(LEN(Region))      FROM SuperstoreStaging
SELECT MIN(LEN(State)),       MAX(LEN(State))       FROM SuperstoreStaging
SELECT MIN(LEN(City)),        MAX(LEN(City))        FROM SuperstoreStaging
SELECT MIN(LEN(Postal_Code)), MAX(LEN(Postal_Code)) FROM SuperstoreStaging


SELECT DISTINCT Country FROM SuperstoreStaging


CREATE TABLE dimGeog(
  Geog_SK    BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  Country    CHAR(13)    NOT NULL,
  Region     VARCHAR(7)  NOT NULL,
  State      VARCHAR(20) NOT NULL,
  City       VARCHAR(17) NOT NULL,
  PostalCode VARCHAR(5)     NOT NULL
)
GO






--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- dimProduct
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Select * from SuperstoreStaging


SELECT DISTINCT Product_ID, Product_Name, Category, Sub_Category
FROM SuperstoreStaging


SELECT MIN(LEN(Product_ID)),   MAX(LEN(Product_ID))   FROM SuperstoreStaging
SELECT MIN(LEN(Product_Name)), MAX(LEN(Product_Name)) FROM SuperstoreStaging
SELECT MIN(LEN(Category)),     MAX(LEN(Category))     FROM SuperstoreStaging
SELECT MIN(LEN(Sub_Category)), MAX(LEN(Sub_Category)) FROM SuperstoreStaging



CREATE TABLE dimProduct(
  Product_SK         BIGINT       NOT NULL IDENTITY(1,1) PRIMARY KEY,
  ProductId          CHAR(15)     NOT NULL,
  ProductName        VARCHAR(127) NOT NULL,
  ProductCategory    VARCHAR(15)  NOT NULL,
  ProductSubCategory VARCHAR(11)  NOT NULL
)
GO





--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- dimCharecter
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Select * from SuperstoreStaging


SELECT DISTINCT Customer_ID, Customer_Name, Segment
FROM SuperstoreStaging

SELECT MIN(LEN(Customer_ID)),   MAX(LEN(Customer_ID))   FROM SuperstoreStaging
SELECT MAX(LEN(Customer_Name)) FROM SuperstoreStaging
SELECT MAX(LEN(Segment))     FROM SuperstoreStaging



CREATE TABLE dimCustomer(
  Customer_SK     BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
  CustomerId      CHAR(8)     NOT NULL,
  CustomerName    VARCHAR(22) NOT NULL,
  CustomerSegment VARCHAR(11) NOT NULL
)
GO





--==============================================================================
-- STEP #3: Populate dim tables
--==============================================================================
USE DW_Superstore_Manual
GO



-- Empty the tables before we start
TRUNCATE TABLE dimShipMode
TRUNCATE TABLE dimGeog
TRUNCATE TABLE dimProduct
TRUNCATE TABLE dimCustomer




------------------------------------------------------------
-- TASK 2
------------------------------------------------------------
-- Attempt to populate the following dim tables:
-- dimShipMode, dimGeog, dimProduct, dimCustomer





