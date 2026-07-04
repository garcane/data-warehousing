/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (fact)
  Purpose : Create FACTOrderItem and wire up referential integrity.
  Grain   : ONE ROW PER ORDER LINE ITEM (transactional fact).
  Measures: Sales, Qty, Discount, Profit (all additive except Discount, which
            is a rate and should be averaged, not summed).
==============================================================================*/

USE DW_Superstore;
GO

DROP TABLE IF EXISTS dbo.FACTOrderItem;
GO

CREATE TABLE dbo.FACTOrderItem (
    Fact_SK      BIGINT       IDENTITY(1,1) NOT NULL,
    Row_Id       BIGINT       NOT NULL,     -- degenerate dimension (source line)
    Order_Id     CHAR(14)     NOT NULL,     -- degenerate dimension (order number)
    Customer_SK  BIGINT       NOT NULL,
    Product_SK   BIGINT       NOT NULL,
    ShipMode_SK  BIGINT       NOT NULL,
    Geog_SK      BIGINT       NOT NULL,
    OrderDate_SK BIGINT       NOT NULL,
    ShipDate     DATE         NOT NULL,
    Sales        FLOAT        NOT NULL,
    Qty          INT          NOT NULL,
    Discount     DECIMAL(3,2) NOT NULL,
    Profit       FLOAT        NOT NULL,
    CONSTRAINT PK_FACTOrderItem PRIMARY KEY CLUSTERED (Fact_SK)
);
GO

-- Foreign keys enforce fact-to-dimension referential integrity.
ALTER TABLE dbo.FACTOrderItem WITH CHECK
    ADD CONSTRAINT FK_Fact_Customer FOREIGN KEY (Customer_SK)  REFERENCES dbo.dimCustomer (Customer_SK);
ALTER TABLE dbo.FACTOrderItem WITH CHECK
    ADD CONSTRAINT FK_Fact_Product  FOREIGN KEY (Product_SK)   REFERENCES dbo.dimProduct  (Product_SK);
ALTER TABLE dbo.FACTOrderItem WITH CHECK
    ADD CONSTRAINT FK_Fact_ShipMode FOREIGN KEY (ShipMode_SK)  REFERENCES dbo.dimShipMode (ShipMode_SK);
ALTER TABLE dbo.FACTOrderItem WITH CHECK
    ADD CONSTRAINT FK_Fact_Geog     FOREIGN KEY (Geog_SK)      REFERENCES dbo.dimGeog     (Geog_SK);
ALTER TABLE dbo.FACTOrderItem WITH CHECK
    ADD CONSTRAINT FK_Fact_Date     FOREIGN KEY (OrderDate_SK) REFERENCES dbo.dimDate     (Date_SK);
GO

PRINT 'Fact table FACTOrderItem created with foreign keys.';
GO
