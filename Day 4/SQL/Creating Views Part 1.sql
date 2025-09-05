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
