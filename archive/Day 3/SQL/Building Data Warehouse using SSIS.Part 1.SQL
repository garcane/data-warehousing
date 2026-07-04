-- Code #1
-- Create new database for our project
USE master
GO
DROP DATABASE IF EXISTS DW_Superstore_SSIS
GO
CREATE DATABASE DW_Superstore_SSIS
GO
ALTER AUTHORIZATION ON DATABASE::DW_Superstore_SSIS TO SA
GO
USE DW_Superstore_SSIS
GO


USE DW_Superstore_SSIS
GO
DROP TABLE IF EXISTS SuperstoreStaging
GO
CREATE TABLE SuperstoreStaging(
    [Row ID]        BIGINT,
    [Order ID]      nvarchar(255),
    [Order Date]    DATE,
    [Ship Date]     DATE,
    [Ship Mode]     nvarchar(255),
    [Customer ID]   nvarchar(255),
    [Customer Name] nvarchar(255),
    [Segment]       nvarchar(255),
    [Country]       nvarchar(255),
    [City]          nvarchar(255),
    [State]         nvarchar(255),
    [Postal Code]   NCHAR(5),
    [Region]        nvarchar(255),
    [Product ID]    nvarchar(255),
    [Category]      nvarchar(255),
    [Sub-Category]  nvarchar(255),
    [Product Name]  nvarchar(255),
    [Sales]         float,
    [Quantity]      INT,
    [Discount]      DECIMAL(3,2),
    [Profit]        float
)



SELECT COUNT(*) FROM SuperstoreStaging



-- Create table dimCustomer
CREATE TABLE dimCustomer(
  Customer_SK     BIGINT        NOT NULL IDENTITY(1,1) PRIMARY KEY,
  CustomerId      NVARCHAR(255) NOT NULL,
  CustomerName    NVARCHAR(255) NOT NULL,
  CustomerSegment NVARCHAR(255) NOT NULL
)


SELECT COUNT(*) FROM dimCustomer
