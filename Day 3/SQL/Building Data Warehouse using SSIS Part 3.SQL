USE DW_Superstore_SSIS
GO

DROP TABLE IF EXISTS dimDate
GO
CREATE TABLE dimDate (
    Date_SK       BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
    DateValue     DATE        NOT NULL,
    Year          SMALLINT    NOT NULL,
    Quarter       TINYINT     NOT NULL,
    Month         TINYINT     NOT NULL,
    MonthName     VARCHAR(10) NOT NULL,
    Day           TINYINT     NOT NULL,
    Weekday       TINYINT     NOT NULL,
    WeekdayName   VARCHAR(10) NOT NULL
)
GO

USE DW_Superstore_SSIS
GO

DROP TABLE IF EXISTS dimDate
GO
CREATE TABLE dimDate (
    Date_SK       BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
    DateValue     DATE        NOT NULL,
    Year          SMALLINT    NOT NULL,
    Quarter       TINYINT     NOT NULL,
    Month         TINYINT     NOT NULL,
    MonthName     VARCHAR(10) NOT NULL,
    Day           TINYINT     NOT NULL,
    Weekday       TINYINT     NOT NULL,
    WeekdayName   VARCHAR(10) NOT NULL
)
GO

USE DW_Superstore_SSIS
GO

DROP PROCEDURE IF EXISTS CreateDimDate
GO
CREATE PROCEDURE CreateDimDate
    @start DATE,
    @end DATE
AS
BEGIN
    DECLARE @current DATE = @start;
    WHILE @current <= @end
    BEGIN
        INSERT INTO dimDate (DateValue, Year, Quarter, Month, MonthName, Day, Weekday, WeekdayName)
        VALUES (
            @current,
            YEAR(@current),
            DATEPART(QUARTER, @current),
            MONTH(@current),
            DATENAME(MONTH, @current),
            DAY(@current),
            DATEPART(WEEKDAY, @current),
            DATENAME(WEEKDAY, @current)
        );
        SET @current = DATEADD(DAY, 1, @current);
    END
END
GO







-- Code #12
-- Create FACTs table
DROP TABLE IF EXISTS FACTOrderItem
GO
CREATE TABLE FACTOrderItem(
  Fact_SK      BIGINT        NOT NULL IDENTITY(1,1) PRIMARY KEY,
  Row_Id       INT           NOT NULL,
  Order_Id     NVARCHAR(255) NOT NULL,
  Customer_SK  BIGINT        NOT NULL FOREIGN KEY REFERENCES dimCustomer(Customer_SK),
  Product_SK   BIGINT        NOT NULL FOREIGN KEY REFERENCES dimProduct(Product_SK),
  ShipMode_SK  BIGINT        NOT NULL FOREIGN KEY REFERENCES dimShipMode(ShipMode_SK),
  Geog_SK      BIGINT        NOT NULL FOREIGN KEY REFERENCES dimGeog(Geog_SK),
  OrderDate_SK BIGINT        NOT NULL FOREIGN KEY REFERENCES dimDate(Date_SK),
  ShipDate     DATE          NOT NULL,
  Sales        FLOAT         NOT NULL,
  Qty          INT           NOT NULL,
  Discount     DECIMAL(3,2)  NOT NULL,
  Profit       FLOAT         NOT NULL
)



-- Code #13
-- Emptying tables
DELETE FROM SuperstoreStaging
DELETE FROM FACTOrderItem
DELETE FROM dimCustomer
DELETE FROM dimProduct
DELETE FROM dimShipMode
DELETE FROM dimGeog
DELETE FROM dimDate



---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- FINAL CHECK
---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Code #14
USE DW_Superstore_SSIS
GO
DELETE FROM SuperstoreStaging
DELETE FROM FACTOrderItem
DELETE FROM dimCustomer
DELETE FROM dimProduct
DELETE FROM dimShipMode
DELETE FROM dimGeog
DELETE FROM dimDate

-- Run SSIS Project THREE times
-- (and make sure it executes three times without errors)

-- Code #15
USE DW_Superstore_SSIS
GO
SELECT COUNT(*) FROM SuperstoreStaging -- 9994
SELECT COUNT(*) FROM dimCustomer       -- 794 (not 793)
SELECT COUNT(*) FROM dimProduct        -- 1894
SELECT COUNT(*) FROM dimShipMode       -- 4
SELECT COUNT(*) FROM dimGeog           -- 632
SELECT COUNT(*) FROM dimDate           -- 1461 (not 1458)
SELECT COUNT(*) FROM FACTOrderItem     -- 9994
---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- FINAL CHECK END
---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
