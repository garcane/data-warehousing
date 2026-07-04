/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (dimensions)
  Purpose : Create the five conformed dimensions in the `dw` schema.
  ------------------------------------------------------------------------------
  Dialect mapping vs SQL Server:
    IDENTITY(1,1)  ->  GENERATED ALWAYS AS IDENTITY   (SQL:2003 standard)
    PRIMARY KEY CLUSTERED  ->  PRIMARY KEY
        PostgreSQL has NO clustered indexes. The PK is a normal b-tree; physical
        ordering is managed separately via the CLUSTER command (see indexes/).
==============================================================================*/

DROP TABLE IF EXISTS dw.fact_order_item CASCADE;
DROP TABLE IF EXISTS dw.dim_ship_mode   CASCADE;
DROP TABLE IF EXISTS dw.dim_geog        CASCADE;
DROP TABLE IF EXISTS dw.dim_product     CASCADE;
DROP TABLE IF EXISTS dw.dim_customer    CASCADE;
DROP TABLE IF EXISTS dw.dim_date        CASCADE;

--------------------------------------------------------------------------------
-- dim_ship_mode
--------------------------------------------------------------------------------
CREATE TABLE dw.dim_ship_mode (
    ship_mode_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ship_mode    VARCHAR(14) NOT NULL
);

--------------------------------------------------------------------------------
-- dim_geog
--------------------------------------------------------------------------------
CREATE TABLE dw.dim_geog (
    geog_sk     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country     CHAR(13)    NOT NULL,
    region      VARCHAR(7)  NOT NULL,
    state       VARCHAR(20) NOT NULL,
    city        VARCHAR(17) NOT NULL,
    postal_code CHAR(5)     NOT NULL
);

--------------------------------------------------------------------------------
-- dim_product  (natural key = product_id + product_name)
--------------------------------------------------------------------------------
CREATE TABLE dw.dim_product (
    product_sk           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id           CHAR(15)     NOT NULL,
    product_name         VARCHAR(127) NOT NULL,
    product_category     VARCHAR(15)  NOT NULL,
    product_sub_category VARCHAR(11)  NOT NULL
);

--------------------------------------------------------------------------------
-- dim_customer  (segment denormalised in - Kimball style, deliberately not 3NF)
--------------------------------------------------------------------------------
CREATE TABLE dw.dim_customer (
    customer_sk      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id      CHAR(8)     NOT NULL,
    customer_name    VARCHAR(22) NOT NULL,
    customer_segment VARCHAR(11) NOT NULL
);

--------------------------------------------------------------------------------
-- dim_date  (conformed calendar; one row per day)
--   Reserved words like "day"/"month"/"year" are fine as column names in
--   PostgreSQL without bracket-quoting (unlike SQL Server's [Year]).
--------------------------------------------------------------------------------
CREATE TABLE dw.dim_date (
    date_sk    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_value DATE     NOT NULL,
    day        INTEGER  NOT NULL,
    week       INTEGER  NOT NULL,
    month      INTEGER  NOT NULL,
    quarter    INTEGER  NOT NULL,
    year       INTEGER  NOT NULL
);
