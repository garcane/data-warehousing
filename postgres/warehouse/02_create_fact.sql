/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (fact)
  Purpose : Create dw.fact_order_item and its fact-to-dimension foreign keys.
  Grain   : One row per order line item.
  ------------------------------------------------------------------------------
  Dialect mapping vs SQL Server:
    DECIMAL(3,2)  ->  NUMERIC(3,2)   (DECIMAL is an accepted alias in PG too)
    FLOAT         ->  DOUBLE PRECISION
    Inline "FOREIGN KEY REFERENCES" is supported identically.
==============================================================================*/

DROP TABLE IF EXISTS dw.fact_order_item CASCADE;

CREATE TABLE dw.fact_order_item (
    fact_sk        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    row_id         BIGINT       NOT NULL,   -- degenerate dimension
    order_id       CHAR(14)     NOT NULL,   -- degenerate dimension
    customer_sk    BIGINT       NOT NULL REFERENCES dw.dim_customer  (customer_sk),
    product_sk     BIGINT       NOT NULL REFERENCES dw.dim_product   (product_sk),
    ship_mode_sk   BIGINT       NOT NULL REFERENCES dw.dim_ship_mode (ship_mode_sk),
    geog_sk        BIGINT       NOT NULL REFERENCES dw.dim_geog      (geog_sk),
    order_date_sk  BIGINT       NOT NULL REFERENCES dw.dim_date      (date_sk),
    ship_date      DATE         NOT NULL,
    sales          DOUBLE PRECISION NOT NULL,
    qty            INTEGER      NOT NULL,
    discount       NUMERIC(3,2) NOT NULL,
    profit         DOUBLE PRECISION NOT NULL
);

COMMENT ON TABLE dw.fact_order_item IS 'Transactional fact - grain: one order line item.';
