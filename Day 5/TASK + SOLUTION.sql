
-- A)
-- Total sales for all the regions

SELECT * FROM dimGeog
SELECT * FROM FACTOrderItem

SELECT g.Region,
	SUM(Sales) AS Total_Sales
FROM FACTOrderItem a
JOIN dimGeog g ON a.Geog_SK = g.Geog_SK
GROUP BY g.Region
ORDER BY Total_Sales DESC

--B
SELECT p.ProductCategory,
	SUM(Sales) AS Total_Sales
FROM FACTOrderItem a
JOIN dimProduct p ON a.Product_SK = p.Product_SK
GROUP BY p.ProductCategory
ORDER BY Total_Sales DESC

--C
SELECT c.CustomerSegment, d.Year, 
       SUM(Sales) AS Total_Sales
FROM FACTOrderItem    a
     JOIN dimCustomer c ON a.Customer_SK  = c.Customer_SK
     JOIN dimDate     d ON a.OrderDate_SK = d.Date_SK
GROUP BY c.CustomerSegment, d.Year
ORDER BY d.Year, c.CustomerSegment

--D
SELECT  d.Year, 
       SUM(Sales) AS Total_Sales
FROM FACTOrderItem    a
     JOIN dimDate     d ON a.OrderDate_SK = d.Date_SK
GROUP BY  d.Year
ORDER BY d.Year

--E
SELECT TOP 5 d.Year, d.[Month],
       SUM(Sales) AS Total_Sales
FROM FACTOrderItem    a
     JOIN dimDate     d ON a.OrderDate_SK = d.Date_SK
GROUP BY  d.Year, d.Month
ORDER BY Total_Sales DESC --ASC OR DESC IS FINE


--F
CREATE VIEW MEGACUBE AS
SELECT d.Year, d.Month, g.Region, c.CustomerSegment, p.ProductCategory,
SUM(Qty) AS Total_Qty,
SUM(Sales) AS Total_Sales
FROM FACTOrderItem a
	JOIN dimGeog     g ON a.Geog_SK      = g.Geog_SK
	JOIN dimProduct  p ON a.Product_SK   = p.Product_SK
     JOIN dimDate     d ON a.OrderDate_SK = d.Date_SK
     JOIN dimCustomer c ON a.Customer_SK  = c.Customer_SK
GROUP BY d.Year, d.Month, g.Region, c.CustomerSegment, p.ProductCategory
--ORDER BY d.Year, d.Month, g.Region, c.CustomerSegment, p.ProductCategory

SELECT * FROM MEGACUBE
ORDER BY Year, Month, Region, CustomerSegment, ProductCategory