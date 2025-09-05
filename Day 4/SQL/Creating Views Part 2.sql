
-- Report         : A summary, calculated by reducing detalisation level
-- Data Warehouse : A database that stores historical data (aka repository)
-- Reporting Layer sits between the dataset (like DW) and a graph in PowerBI*
-- * whenever we say PowerBI - we mean any data visualisation tool
-- Dimension      : An 'important' column a business is interested in
-- Cube           : A report that contains data along several dimensions, 
-- Cube is like a multidimensional report
-- * do not confuse with CUBES feature of MS SQL
USE DW_Superstore_Code
GO


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- THE PROBLEM
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Your manager wants to get a daily report on sales
-- In our example, by 'sales' we mean:
--    1) total quantities
--    2) total sales
-- However, it could be any other grouping
-- (value / price / amount / income) - it does not matter
--
-- 'Daily' could be anything time-based
-- (hourly, weekly, monthly, quarterly, yearly etc)
--
-- In simple words:
-- You need to summarise a field along time-based dimension
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT TOP 5*
FROM FACTOrderItem
ORDER BY Order_Id, Row_Id


-- which field do we need to group by to get the daily report? 
SELECT OrderDate_SK,
       SUM(Qty)   AS Total_Qty,  -- total quantities
       SUM(Sales) AS Total_Sales -- total value (price)
FROM FACTOrderItem
GROUP BY OrderDate_SK
ORDER BY OrderDate_SK


DROP VIEW IF EXISTS DateSales
GO

CREATE VIEW DateSales AS

-- Now we can query DateSales as if it was a table:
SELECT *
FROM DateSales
ORDER BY OrderDate_SK


--  Let's now join it with dimDate
SELECT s.OrderDate_SK,
d.DateValue,
s.Total_Qty, s.Total_Sales,
d.Day, d.Week, d.Month, d.Quarter, d.Year
FROM DateSales s
JOIN dimDate d ON s.OrderDate_SK = d.Date_SK
ORDER BY s.OrderDate_SK


-- Save it as another view!
DROP VIEW IF EXISTS Cube0
GO
CREATE VIEW Cube0 AS
SELECT s.OrderDate_SK, -- keep it just in case
       d.DateValue,
       s.Total_Qty, s.Total_Sales,
       d.Day, d.Week, d.Month, d.Quarter, d.Year
FROM DateSales    s
     JOIN dimDate d ON s.OrderDate_SK = d.Date_SK
GO

-- and query it!
SELECT *
FROM Cube0
ORDER BY DateValue

Lisa Kirke
qa.com
11:09 AM


--Equivalent query without using views
SELECT OrderDate_SK, DateValue,
    SUM(Qty) AS Total_Qty, --total quantities
    SUM(SALES) as Total_Sales,
    d.Day, d.Week, d.Month, d.Quarter, d.Year 

FROM FACTOrderItem f
    JOIN dimDate d ON f.OrderDate_SK = d.Date_SK
GROUP BY OrderDate_SK, DateValue,
    d.Day, d.Week, d.Month, d.Quarter, d.Year 
ORDER BY OrderDate_SK

Lisa Kirke
qa.com
11:15 AM
-- We can now use Cube0 to run different reports along ANY DATE DIMENSION
-- For example, sales report by Year:

SELECT Year,                                               -- SELECT A
       SUM(Total_Qty)             AS Yearly_Total_Qty,
       ROUND(SUM(Total_Sales), 2) AS Yearly_Total_Sales
FROM Cube0
GROUP BY Year
ORDER BY Year


-- Exactly the same output can be obtained directly from the staging table...
SELECT YEAR(Order_Date)     AS Year,                       -- SELECT B
       SUM(Quantity)        AS Yearly_Total_Qty,
       ROUND(SUM(Sales), 2) AS Yearly_Total_Sales
FROM SuperstoreStaging
GROUP BY YEAR(Order_Date)
ORDER BY YEAR(Order_Date)



CREATE VIEW Cube1 AS
SELECT c.Customer_SK, c.CustomerName, g.Region,
g.State,g.City, d.Quarter,
SUM(Qty) AS Total_Qty,
SUM(Sales) AS Total_Sales

FROM FACTOrderItem a
JOIN dimCustomer c ON a. Customer_SK = c .Customer_SK
JOIN dimGeog g ON a. Geog_SK = g. Geog_SK
JOIN dimDate d ON a. OrderDate_SK = d. Date_SK

GROUP BY c.Customer_SK, c.CustomerName, g.Region,
g.State,g.City, d.Quarter


-- Query 1b (getting data from the staging table)

SELECT Customer_ID, Customer_Name,
       Region, State, City,
       YEAR(Order_Date)              AS Year,
       DATEPART(QUARTER, Order_Date) AS Quarter,
       SUM(Quantity) AS Total_Qty,
       SUM(Sales)    AS Total_Sales
FROM SuperstoreStaging
GROUP BY Customer_ID, Customer_Name,
         Region, State, City,
         YEAR(Order_Date),
         DATEPART(QUARTER, Order_Date)
ORDER BY Customer_Name, Customer_ID,
         YEAR(Order_Date),
         DATEPART(QUARTER, Order_Date),
         Region, State, City


CREATE VIEW Cube2 AS
SELECT  d.Year, d.Week,
       p.ProductCategory,
       c.CustomerSegment,
       g.Region,
       SUM(a.Qty)   AS Total_Qty,
       SUM(a.Sales) AS Total_Sales
FROM FACTOrderItem    a
     JOIN dimDate     d ON a.OrderDate_SK = d.Date_SK
     JOIN dimProduct  p ON a.Product_SK   = p.Product_SK
     JOIN dimCustomer c ON a.Customer_SK  = c.Customer_SK
     JOIN dimGeog     g ON a.Geog_SK      = g.Geog_SK
GROUP BY d.Year, d.Week, p.ProductCategory, c.CustomerSegment, g.Region


-- Query 2b (getting data from the staging table)
SELECT * FROM SuperstoreStaging

SELECT YEAR(Order_Date)           AS Year,
       DATEPART(WEEK, Order_Date) AS Week,
       Category,
       Segment,
       Region,
       SUM(Quantity) AS Total_Qty,
       SUM(Sales)    AS Total_Sales
FROM SuperstoreStaging
GROUP BY YEAR(Order_Date), DATEPART(WEEK, Order_Date),
         Category, Segment, Region
ORDER BY YEAR(Order_Date), DATEPART(WEEK, Order_Date),
         Category, Segment, Region
-- 3856 records as well

SELECT			[Year],
				[ProductCategory],
				sum([ProductsSold]) as [ProductsSold],
				sum([SalesAmount]) as [SalesAmount]
FROM			Cube2

GROUP BY		[Year],
				[ProductCategory]

-- 3A 
CREATE VIEW Cube3 AS
SELECT p.ProductCategory, d.[Year],
       SUM(Qty)   AS Total_Qty,
       SUM(Sales) AS Total_Sales
FROM FACTOrderItem   a
     JOIN dimProduct p ON a.Product_SK   = p.Product_SK
     JOIN dimDate    d ON a.OrderDate_SK = d.Date_SK
     GROUP BY p.ProductCategory, d.[Year]
-- Query 3b (getting data from the staging table)
SELECT Category,
       YEAR(Order_Date) AS Year,
       SUM(Quantity)    AS Total_Qty,
       SUM(Sales)       AS Total_Sales
FROM SuperstoreStaging
GROUP BY Category, YEAR(Order_Date)
ORDER BY Category, YEAR(Order_Date)


-- 3c
--CREATE VIEW Cube3 AS
SELECT ProductCategory,[Year],
       SUM(Total_Qty)   AS Total_Qty,
       SUM(Total_Sales) AS Total_Sales
FROM Cube2
     GROUP BY ProductCategory, [Year]
