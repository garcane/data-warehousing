/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (performance)
  Purpose : Non-clustered indexes to accelerate star-join reporting queries.
  Rationale:
    - OLAP stores favour MORE indexes than OLTP because they are read-heavy.
    - Foreign-key columns on the fact table are the primary join predicates,
      so each gets a covering-friendly non-clustered index.
    - Natural-key indexes on dimensions speed up the ETL surrogate-key lookups.
==============================================================================*/

USE DW_Superstore;
GO

-- Fact foreign-key indexes (drive star joins).
CREATE NONCLUSTERED INDEX IX_Fact_Customer  ON dbo.FACTOrderItem (Customer_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Product   ON dbo.FACTOrderItem (Product_SK);
CREATE NONCLUSTERED INDEX IX_Fact_ShipMode  ON dbo.FACTOrderItem (ShipMode_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Geog      ON dbo.FACTOrderItem (Geog_SK);
CREATE NONCLUSTERED INDEX IX_Fact_OrderDate ON dbo.FACTOrderItem (OrderDate_SK);
GO

-- Dimension natural-key indexes (speed up ETL lookups and ad-hoc filtering).
CREATE NONCLUSTERED INDEX IX_dimCustomer_NK ON dbo.dimCustomer (CustomerId);
CREATE NONCLUSTERED INDEX IX_dimProduct_NK  ON dbo.dimProduct  (ProductId, ProductName);
CREATE NONCLUSTERED INDEX IX_dimGeog_NK     ON dbo.dimGeog     (PostalCode, City);
CREATE NONCLUSTERED INDEX IX_dimShipMode_NK ON dbo.dimShipMode (ShipMode);
CREATE UNIQUE NONCLUSTERED INDEX UX_dimDate_DateValue ON dbo.dimDate (DateValue);
GO

PRINT 'Indexes created.';
GO
