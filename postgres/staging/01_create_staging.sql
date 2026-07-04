/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Staging
  Purpose : Create staging.superstore_staging, mirroring the source CSV.
  ------------------------------------------------------------------------------
  Dialect mapping vs SQL Server (see docs/migration-guide.md):
    NVARCHAR(n)   -> VARCHAR(n)    (PostgreSQL text is Unicode by default)
    DATETIME2(7)  -> TIMESTAMP(6)  (max fractional-second precision is 6)
    FLOAT         -> DOUBLE PRECISION
    CHAR(n)       -> CHAR(n)       (identical)
==============================================================================*/

DROP TABLE IF EXISTS staging.superstore_staging;

CREATE TABLE staging.superstore_staging (
    row_id        BIGINT        NOT NULL,
    order_id      VARCHAR(50)   NOT NULL,
    order_date    DATE          NOT NULL,
    ship_date     TIMESTAMP(6)  NOT NULL,
    ship_mode     VARCHAR(14)   NOT NULL,
    customer_id   CHAR(8)       NOT NULL,
    customer_name VARCHAR(50)   NOT NULL,
    segment       VARCHAR(50)   NOT NULL,
    country       VARCHAR(50)   NOT NULL,
    city          VARCHAR(17)   NOT NULL,
    state         VARCHAR(50)   NOT NULL,
    postal_code   CHAR(5)       NOT NULL,
    region        VARCHAR(50)   NOT NULL,
    product_id    CHAR(15)      NOT NULL,
    category      VARCHAR(50)   NOT NULL,
    sub_category  VARCHAR(50)   NOT NULL,
    product_name  VARCHAR(127)  NOT NULL,
    sales         DOUBLE PRECISION NOT NULL,
    quantity      INTEGER       NOT NULL,
    discount      DOUBLE PRECISION NOT NULL,
    profit        DOUBLE PRECISION NOT NULL
);

COMMENT ON TABLE staging.superstore_staging IS 'Raw landing table - one row per source CSV line.';
