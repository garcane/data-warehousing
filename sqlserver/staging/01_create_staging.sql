/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Staging (landing)
  Purpose : Create the SuperstoreStaging table that mirrors the source CSV 1:1.
  Design  : Raw ingestion layer - minimal transformation, preserve source
            fidelity. Column names/types match the flat file so the load can be
            a straight BULK INSERT.
==============================================================================*/

USE DW_Superstore;
GO

DROP TABLE IF EXISTS dbo.SuperstoreStaging;
GO

CREATE TABLE dbo.SuperstoreStaging (
    Row_ID        BIGINT        NOT NULL,   -- source line identifier
    Order_ID      NVARCHAR(50)  NOT NULL,   -- e.g. CA-2016-152156
    Order_Date    DATE          NOT NULL,
    Ship_Date     DATETIME2(7)  NOT NULL,
    Ship_Mode     VARCHAR(14)   NOT NULL,
    Customer_ID   CHAR(8)       NOT NULL,   -- e.g. CG-12520
    Customer_Name NVARCHAR(50)  NOT NULL,
    Segment       NVARCHAR(50)  NOT NULL,
    Country       NVARCHAR(50)  NOT NULL,
    City          VARCHAR(17)   NOT NULL,
    State         NVARCHAR(50)  NOT NULL,
    Postal_Code   CHAR(5)       NOT NULL,
    Region        NVARCHAR(50)  NOT NULL,
    Product_ID    CHAR(15)      NOT NULL,   -- e.g. FUR-BO-10001798
    Category      NVARCHAR(50)  NOT NULL,
    Sub_Category  NVARCHAR(50)  NOT NULL,
    Product_Name  VARCHAR(127)  NOT NULL,
    Sales         FLOAT         NOT NULL,
    Quantity      INT           NOT NULL,
    Discount      FLOAT         NOT NULL,
    Profit        FLOAT         NOT NULL
);
GO

PRINT 'Table dbo.SuperstoreStaging created.';
GO
