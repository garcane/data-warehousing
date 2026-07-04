USE DW_Superstore_SSIS
GO

-- dimProduct (4 fields + SK)
DROP TABLE IF EXISTS dimProduct
GO
CREATE TABLE dimProduct (
    Product_SK      BIGINT        NOT NULL IDENTITY(1,1) PRIMARY KEY,
    ProductId       NVARCHAR(255) NOT NULL,
    Category        NVARCHAR(255) NOT NULL,
    SubCategory     NVARCHAR(255) NOT NULL,
    ProductName     NVARCHAR(255) NOT NULL
)
GO

-- dimShipMode (1 field + SK)
DROP TABLE IF EXISTS dimShipMode
GO
CREATE TABLE dimShipMode (
    ShipMode_SK     BIGINT        NOT NULL IDENTITY(1,1) PRIMARY KEY,
    ShipMode        NVARCHAR(255) NOT NULL
)
GO

-- dimGeog (5 fields + SK)
DROP TABLE IF EXISTS dimGeog
GO
CREATE TABLE dimGeog (
    Geog_SK         BIGINT        NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Country         NVARCHAR(255) NOT NULL,
    City            NVARCHAR(255) NOT NULL,
    State           NVARCHAR(255) NOT NULL,
    PostalCode      NCHAR(5)      NOT NULL,
    Region          NVARCHAR(255) NOT NULL
)
GO

USE DW_Superstore_SSIS
GO

-- Checking...
-- Run SSIS project at least three times.
-- and Check number of records in each table:
SELECT COUNT(*) FROM SuperstoreStaging   -- 9994
SELECT COUNT(*) FROM dimCustomer         -- 794
SELECT COUNT(*) FROM dimProduct          -- 1894
SELECT COUNT(*) FROM dimShipMode         -- 4
SELECT COUNT(*) FROM dimGeog             -- 632

