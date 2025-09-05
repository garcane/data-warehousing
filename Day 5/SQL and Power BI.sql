--cache
--Query Caching
-- Data Caching

-- OLTP ---X----> PowerBI

-- OLTP ---> OLAP---X----> PowerBI

-- THE BEST STEP IS :
-- OLTP ---> OLAP---> Reporting Layer ----> PowerBI

-- if you T database is small, OLAP may not be needed
-- OLTP --->  Reporting Layer ----> PowerBI

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

-- Basic report on Customer Segment:
SELECT c.CustomerSegment,
       ROUND(SUM(Sales), 0) AS Total_Sales
FROM FACTOrderItem    a
     JOIN dimCustomer c ON a.Customer_SK = c.Customer_SK
GROUP BY c.CustomerSegment
ORDER BY Total_Sales DESC


-- Let's say we've got another customer
-- (that belongs to a new CustomerSegment):
INSERT INTO dimCustomer(CustomerId, CustomerName, CustomerSegment)
VALUES('YY-007', 'James Bond', 'SecretAgent')

-- Query with the LEFT JOIN:
SELECT c.CustomerSegment,
       COALESCE(ROUND(SUM(Sales), 0), 0) AS Total_Sales
FROM dimCustomer c
     LEFT JOIN FACTOrderItem a ON c.Customer_SK = a.Customer_SK
GROUP BY c.CustomerSegment
ORDER BY Total_Sales DESC

CREATE VIEW vCustomerSegment AS
SELECT c.CustomerSegment,
       COALESCE(ROUND(SUM(Sales), 0), 0) AS Total_Sales
FROM dimCustomer c
     LEFT JOIN FACTOrderItem a ON c.Customer_SK = a.Customer_SK
GROUP BY c.CustomerSegment
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

--QUERY FOLDING

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

-- Get data - SQL Server, enter server and database name,
-- expand Advanced options and paste SQL code
-- (don't forget to specify database name)
-- [maybe rename Query1 to something meaningful]