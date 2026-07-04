/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (fact load)
  Purpose : Load FACTOrderItem by resolving each staging row's natural keys to
            dimension surrogate keys (the classic "surrogate key pipeline").
  Grain   : One row per order line item.
  Expected row count: 9994.
==============================================================================*/

USE DW_Superstore;
GO

DELETE FROM dbo.FACTOrderItem;
GO

INSERT INTO dbo.FACTOrderItem (
    Row_Id, Order_Id, Customer_SK, Product_SK, ShipMode_SK, Geog_SK,
    OrderDate_SK, ShipDate, Sales, Qty, Discount, Profit
)
SELECT
    s.Row_ID,
    s.Order_ID,
    c.Customer_SK,
    p.Product_SK,
    m.ShipMode_SK,
    g.Geog_SK,
    d.Date_SK,
    s.Ship_Date,
    s.Sales,
    s.Quantity,
    s.Discount,
    s.Profit
FROM dbo.SuperstoreStaging AS s
    JOIN dbo.dimCustomer AS c ON s.Customer_ID = c.CustomerId
    JOIN dbo.dimProduct  AS p ON s.Product_ID  = p.ProductId  AND s.Product_Name = p.ProductName
    JOIN dbo.dimShipMode AS m ON s.Ship_Mode   = m.ShipMode
    JOIN dbo.dimGeog     AS g ON s.Postal_Code = g.PostalCode AND s.City = g.City
    JOIN dbo.dimDate     AS d ON s.Order_Date  = d.DateValue;
GO

SELECT COUNT(*) AS FactRowCount FROM dbo.FACTOrderItem;   -- expect 9994
GO

PRINT 'FACTOrderItem loaded.';
GO
