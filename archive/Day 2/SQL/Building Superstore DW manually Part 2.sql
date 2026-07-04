-- Empty the tables before we start
TRUNCATE TABLE dimShipMode
TRUNCATE TABLE dimGeog
TRUNCATE TABLE dimProduct
TRUNCATE TABLE dimCustomer


Select * from SuperstoreStaging

Select * from dimShipMode

------------------------------------------------------------
-- TASK 2
------------------------------------------------------------
-- Attempt to populate the following dim tables:
-- dimShipMode, dimGeog, dimProduct, dimCustomer
-- dimShipMode (expect 4)
INSERT INTO dimShipMode (ShipMode)
SELECT DISTINCT Ship_Mode
FROM SuperstoreStaging
ORDER BY Ship_Mode;

Select * from SuperstoreStaging

Select * from dimShipMode


-- dimGeog (expect 632)
INSERT INTO dimGeog (Country, Region, State, City, PostalCode)
SELECT DISTINCT Country, Region, State, City, Postal_Code
FROM SuperstoreStaging
ORDER BY Country;


Select * from SuperstoreStaging

Select * from dimGeog


-- dimProduct (expect 1894)
INSERT INTO dimProduct
SELECT DISTINCT Product_ID, Product_Name, Category, Sub_Category
FROM SuperstoreStaging
ORDER BY Product_Name;


Select * from SuperstoreStaging

Select * from dimProduct




-- dimCustomer (expect 794)
INSERT INTO dimCustomer (CustomerId, CustomerName, CustomerSegment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment
FROM SuperstoreStaging
ORDER BY Customer_ID, Customer_Name;





Select * from SuperstoreStaging

Select * from dimCustomer

-- Notice number of records in each table, you should get:
-- 4, 632, 1894, 794


-- Final check before moving to the next step
SELECT COUNT(*) FROM SuperstoreStaging -- must be 9994
SELECT COUNT(*) FROM dimShipMode       -- must be 4
SELECT COUNT(*) FROM dimGeog           -- must be 632
SELECT COUNT(*) FROM dimProduct        -- must be 1894
SELECT COUNT(*) FROM dimCustomer       -- must be 794




--==============================================================================
-- STEP #4: Create and populate dimDate table
--==============================================================================
USE DW_Superstore_Manual
GO

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Create table dimDate
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Create table
DROP TABLE IF EXISTS FACTOrderItem
DROP TABLE IF EXISTS dimDate
GO
CREATE TABLE dimDate(
  Date_SK   BIGINT   NOT NULL IDENTITY(1,1) PRIMARY KEY, -- e.g. 3
  DateValue DATE     NOT NULL,                           -- e.g. 5 Jan 2014 (05/01/2014 or 2014-01-05)
  [Day]     TINYINT  NOT NULL,                           -- e.g. 5
  [Week]    TINYINT  NOT NULL,                           -- e.g. 1 or 2
  [Month]   TINYINT  NOT NULL,                           -- e.g. 1
  [Quarter] TINYINT  NOT NULL,                           -- e.g. 1
  [Year]    SMALLINT NOT NULL                            -- e.g. 2014
)
GO



--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- But why on Earth do we need it?
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Consider the simplest yearly report (based on field Order_Date):
SELECT YEAR(Order_Date) AS Year,
       SUM(Quantity)    AS Total_Qty,
       SUM(Sales)       AS Total_Sales
FROM SuperstoreStaging
WHERE    YEAR(Order_Date) > 2014 -- using index on Order_Date is not possible because of the function
GROUP BY YEAR(Order_Date)        -- using index on Order_Date is not possible because of the function
ORDER BY YEAR(Order_Date)        -- using index on Order_Date is not possible because of the function




SELECT *
FROM SuperstoreStaging
WHERE Order_Date = '2014-01-10'

CREATE INDEX i1 ON SuperstoreStaging(Order_Date)


DROP   INDEX i1 ON SuperstoreStaging

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Populate table dimDate
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- First of all, get the range of Order_Date dates...
SELECT MIN(Order_Date) AS Min_Order_Date,
       MAX(Order_Date) AS Max_Order_Date
FROM SuperstoreStaging

SELECT COUNT(DISTINCT Order_Date) FROM SuperstoreStaging


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The rest of the code MUST be executed as a single batch
-- This is where you will start loving Transact-SQL (T-SQL)
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- declare variables to hold the start and end date
DECLARE @StartDate DATE
DECLARE @EndDate   DATE
SET @StartDate = (SELECT MIN(Order_Date) AS Min_Order_Date FROM SuperstoreStaging)
SET @EndDate   = (SELECT MAX(Order_Date) AS Max_Order_Date FROM SuperstoreStaging)

-- see what's inside
SELECT @StartDate
SELECT @EndDate

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
           CASE WHEN Month(@LoopDate) IN (1, 2, 3) THEN 1
                WHEN Month(@LoopDate) IN (4, 5, 6) THEN 2
                WHEN Month(@LoopDate) IN (7, 8, 9) THEN 3
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


SELECT * FROM dimDate
Order by Date_SK

drop table dimDate



SELECT COUNT(*) FROM SuperstoreStaging -- must be 9994
SELECT COUNT(*) FROM dimShipMode       -- must be 4
SELECT COUNT(*) FROM dimGeog           -- must be 632
SELECT COUNT(*) FROM dimProduct        -- must be 1894
SELECT COUNT(*) FROM dimCustomer       -- must be 794
SELECT COUNT(*) FROM dimDate           -- must be 1458



--==============================================================================
-- STEP #5: Create and populate FACTs table
--==============================================================================
SELECT TOP 18 *
FROM SuperstoreStaging
ORDER BY Order_Id, Row_Id



SELECT TOP 18 *
FROM SuperstoreStaging
ORDER BY Order_Id, Row_Id
SELECT COUNT (DISTINCT ORDER_ID) FROM SuperstoreStaging




-- Create table
DROP TABLE IF EXISTS FACTOrderItem
GO
CREATE TABLE FACTOrderItem(
  Fact_SK      BIGINT       NOT NULL IDENTITY(1,1) PRIMARY KEY,
  Row_Id       INT          NOT NULL,
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