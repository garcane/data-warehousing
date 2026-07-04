/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (orchestration)
  Object  : dbo.usp_Load_SuperstoreDW
  Purpose : One-call, transactionally-safe full reload of the warehouse from an
            already-populated SuperstoreStaging table.
  Contract: - Assumes SuperstoreStaging is loaded (run staging\02_load_staging).
            - Rebuilds dimensions, dimDate and the fact within a transaction.
            - On any error, the whole reload is rolled back and re-thrown.
  Usage   : EXEC dbo.usp_Load_SuperstoreDW;
==============================================================================*/

USE DW_Superstore;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_SuperstoreDW
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- any error aborts the batch and rolls back

    BEGIN TRY
        BEGIN TRANSACTION;

        ------------------------------------------------------------------
        -- 1. Reset targets (fact first because of the foreign keys).
        ------------------------------------------------------------------
        DELETE FROM dbo.FACTOrderItem;
        TRUNCATE TABLE dbo.dimShipMode;
        TRUNCATE TABLE dbo.dimGeog;
        TRUNCATE TABLE dbo.dimProduct;
        TRUNCATE TABLE dbo.dimCustomer;
        TRUNCATE TABLE dbo.dimDate;

        ------------------------------------------------------------------
        -- 2. Load conformed dimensions.
        ------------------------------------------------------------------
        INSERT INTO dbo.dimShipMode (ShipMode)
        SELECT DISTINCT Ship_Mode FROM dbo.SuperstoreStaging;

        INSERT INTO dbo.dimGeog (Country, Region, State, City, PostalCode)
        SELECT DISTINCT Country, Region, State, City, Postal_Code FROM dbo.SuperstoreStaging;

        INSERT INTO dbo.dimProduct (ProductId, ProductName, ProductCategory, ProductSubCategory)
        SELECT DISTINCT Product_ID, Product_Name, Category, Sub_Category FROM dbo.SuperstoreStaging;

        INSERT INTO dbo.dimCustomer (CustomerId, CustomerName, CustomerSegment)
        SELECT DISTINCT Customer_ID, Customer_Name, Segment FROM dbo.SuperstoreStaging;

        ------------------------------------------------------------------
        -- 3. Generate the calendar dimension for the fact date range.
        ------------------------------------------------------------------
        DECLARE @StartDate DATE = (SELECT MIN(Order_Date) FROM dbo.SuperstoreStaging);
        DECLARE @EndDate   DATE = (SELECT MAX(Order_Date) FROM dbo.SuperstoreStaging);

        ;WITH Calendar AS (
            SELECT @StartDate AS DateValue
            UNION ALL
            SELECT DATEADD(DAY, 1, DateValue) FROM Calendar WHERE DateValue < @EndDate
        )
        INSERT INTO dbo.dimDate (DateValue, [Day], [Week], [Month], [Quarter], [Year])
        SELECT DateValue, DAY(DateValue), DATEPART(WEEK, DateValue),
               MONTH(DateValue), DATEPART(QUARTER, DateValue), YEAR(DateValue)
        FROM Calendar
        OPTION (MAXRECURSION 0);

        ------------------------------------------------------------------
        -- 4. Load the fact via the surrogate-key pipeline.
        ------------------------------------------------------------------
        INSERT INTO dbo.FACTOrderItem (
            Row_Id, Order_Id, Customer_SK, Product_SK, ShipMode_SK, Geog_SK,
            OrderDate_SK, ShipDate, Sales, Qty, Discount, Profit
        )
        SELECT
            s.Row_ID, s.Order_ID, c.Customer_SK, p.Product_SK, m.ShipMode_SK,
            g.Geog_SK, d.Date_SK, s.Ship_Date, s.Sales, s.Quantity, s.Discount, s.Profit
        FROM dbo.SuperstoreStaging AS s
            JOIN dbo.dimCustomer AS c ON s.Customer_ID = c.CustomerId
            JOIN dbo.dimProduct  AS p ON s.Product_ID  = p.ProductId  AND s.Product_Name = p.ProductName
            JOIN dbo.dimShipMode AS m ON s.Ship_Mode   = m.ShipMode
            JOIN dbo.dimGeog     AS g ON s.Postal_Code = g.PostalCode AND s.City = g.City
            JOIN dbo.dimDate     AS d ON s.Order_Date  = d.DateValue;

        COMMIT TRANSACTION;
        PRINT 'usp_Load_SuperstoreDW: warehouse reloaded successfully.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT 'usp_Load_SuperstoreDW: load FAILED and was rolled back.';
        THROW;   -- re-raise to the caller / job so failures are visible
    END CATCH
END;
GO

PRINT 'Procedure dbo.usp_Load_SuperstoreDW created.';
GO
