/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (performance)
  Purpose : Indexes to accelerate star-join reporting queries.
  ------------------------------------------------------------------------------
  Dialect notes vs SQL Server:
    - PostgreSQL has NO clustered indexes. The nearest analogue is the CLUSTER
      command, which physically reorders a table ONCE to match an index (it is
      not maintained automatically). We CLUSTER the fact on the order-date index
      because time-range scans are the most common access pattern.
    - All these are ordinary b-tree indexes (the default).
==============================================================================*/

-- Fact foreign-key indexes (drive star joins).
CREATE INDEX IF NOT EXISTS ix_fact_customer   ON dw.fact_order_item (customer_sk);
CREATE INDEX IF NOT EXISTS ix_fact_product    ON dw.fact_order_item (product_sk);
CREATE INDEX IF NOT EXISTS ix_fact_ship_mode  ON dw.fact_order_item (ship_mode_sk);
CREATE INDEX IF NOT EXISTS ix_fact_geog       ON dw.fact_order_item (geog_sk);
CREATE INDEX IF NOT EXISTS ix_fact_order_date ON dw.fact_order_item (order_date_sk);

-- Dimension natural-key indexes (ETL lookups + ad-hoc filtering).
CREATE INDEX IF NOT EXISTS ix_dim_customer_nk  ON dw.dim_customer  (customer_id);
CREATE INDEX IF NOT EXISTS ix_dim_product_nk   ON dw.dim_product   (product_id, product_name);
CREATE INDEX IF NOT EXISTS ix_dim_geog_nk      ON dw.dim_geog      (postal_code, city);
CREATE INDEX IF NOT EXISTS ix_dim_ship_mode_nk ON dw.dim_ship_mode (ship_mode);
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_date_date_value ON dw.dim_date (date_value);

-- Refresh planner statistics after bulk load + indexing.
ANALYZE dw.fact_order_item;
ANALYZE dw.dim_customer;
ANALYZE dw.dim_product;
ANALYZE dw.dim_geog;
ANALYZE dw.dim_ship_mode;
ANALYZE dw.dim_date;

-- Physically order the fact by order date (one-off; see note above).
CLUSTER dw.fact_order_item USING ix_fact_order_date;
