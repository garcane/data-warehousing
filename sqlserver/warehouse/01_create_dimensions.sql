/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (conformed dimensions)
  Purpose : Create the five dimension tables of the Superstore star schema.
  Model   : Kimball dimensional model. Every dimension carries a surrogate key
            (BIGINT IDENTITY) that is independent of the operational natural key.
==============================================================================*/

USE DW_Superstore;
GO

-- Fact is dropped first because it references the dimensions.
DROP TABLE IF EXISTS dbo.FACTOrderItem;
DROP TABLE IF EXISTS dbo.dimShipMode;
DROP TABLE IF EXISTS dbo.dimGeog;
DROP TABLE IF EXISTS dbo.dimProduct;
DROP TABLE IF EXISTS dbo.dimCustomer;
DROP TABLE IF EXISTS dbo.dimDate;
GO

--------------------------------------------------------------------------------
-- dimShipMode : how an order line was shipped (grain: one row per ship mode).
--------------------------------------------------------------------------------
CREATE TABLE dbo.dimShipMode (
    ShipMode_SK BIGINT      IDENTITY(1,1) NOT NULL,
    ShipMode    VARCHAR(14) NOT NULL,
    CONSTRAINT PK_dimShipMode PRIMARY KEY CLUSTERED (ShipMode_SK)
);
GO

--------------------------------------------------------------------------------
-- dimGeog : geography (grain: one row per Country/Region/State/City/PostalCode).
--------------------------------------------------------------------------------
CREATE TABLE dbo.dimGeog (
    Geog_SK    BIGINT      IDENTITY(1,1) NOT NULL,
    Country    CHAR(13)    NOT NULL,
    Region     VARCHAR(7)  NOT NULL,
    State      VARCHAR(20) NOT NULL,
    City       VARCHAR(17) NOT NULL,
    PostalCode CHAR(5)     NOT NULL,
    CONSTRAINT PK_dimGeog PRIMARY KEY CLUSTERED (Geog_SK)
);
GO

--------------------------------------------------------------------------------
-- dimProduct : product master (grain: one row per product).
--   Natural key = ProductId (+ ProductName to disambiguate reused IDs).
--------------------------------------------------------------------------------
CREATE TABLE dbo.dimProduct (
    Product_SK         BIGINT       IDENTITY(1,1) NOT NULL,
    ProductId          CHAR(15)     NOT NULL,
    ProductName        VARCHAR(127) NOT NULL,
    ProductCategory    VARCHAR(15)  NOT NULL,
    ProductSubCategory VARCHAR(11)  NOT NULL,
    CONSTRAINT PK_dimProduct PRIMARY KEY CLUSTERED (Product_SK)
);
GO

--------------------------------------------------------------------------------
-- dimCustomer : customer master (grain: one row per customer).
--   Segment is intentionally denormalised into this dimension (Kimball style),
--   which is deliberately against 3NF for reporting performance.
--------------------------------------------------------------------------------
CREATE TABLE dbo.dimCustomer (
    Customer_SK     BIGINT      IDENTITY(1,1) NOT NULL,
    CustomerId      CHAR(8)     NOT NULL,
    CustomerName    VARCHAR(22) NOT NULL,
    CustomerSegment VARCHAR(11) NOT NULL,
    CONSTRAINT PK_dimCustomer PRIMARY KEY CLUSTERED (Customer_SK)
);
GO

--------------------------------------------------------------------------------
-- dimDate : conformed calendar dimension (grain: one row per calendar day).
--   Generated for the full order-date range so reports can slice by any
--   time attribute without applying functions to the fact table.
--------------------------------------------------------------------------------
CREATE TABLE dbo.dimDate (
    Date_SK   BIGINT   IDENTITY(1,1) NOT NULL,
    DateValue DATE     NOT NULL,
    [Day]     INT      NOT NULL,
    [Week]    INT      NOT NULL,
    [Month]   INT      NOT NULL,
    [Quarter] INT      NOT NULL,
    [Year]    INT      NOT NULL,
    CONSTRAINT PK_dimDate PRIMARY KEY CLUSTERED (Date_SK)
);
GO

PRINT 'Dimension tables created.';
GO
