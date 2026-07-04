/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (dimension load)
  Purpose : Populate the master dimensions from staging.
  Method  : INSERT ... SELECT DISTINCT (set-based, idempotent via TRUNCATE).
  Expected: dim_ship_mode = 4, dim_geog = 632, dim_product = 1894, dim_customer = 794.
  ------------------------------------------------------------------------------
  Dialect note: TRUNCATE ... RESTART IDENTITY resets the identity sequence so a
  rebuild always starts surrogate keys at 1 (SQL Server's TRUNCATE reseeds too).
  RESTART IDENTITY CASCADE also truncates fact_order_item (which FKs to these).
==============================================================================*/

TRUNCATE TABLE
    dw.fact_order_item,
    dw.dim_ship_mode,
    dw.dim_geog,
    dw.dim_product,
    dw.dim_customer
RESTART IDENTITY;

-- dim_ship_mode
INSERT INTO dw.dim_ship_mode (ship_mode)
SELECT DISTINCT ship_mode
FROM staging.superstore_staging
ORDER BY ship_mode;

-- dim_geog
INSERT INTO dw.dim_geog (country, region, state, city, postal_code)
SELECT DISTINCT country, region, state, city, postal_code
FROM staging.superstore_staging
ORDER BY country, postal_code, city, state;

-- dim_product
INSERT INTO dw.dim_product (product_id, product_name, product_category, product_sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category
FROM staging.superstore_staging
ORDER BY product_id, product_name;

-- dim_customer  (segment denormalised in - by design)
INSERT INTO dw.dim_customer (customer_id, customer_name, customer_segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM staging.superstore_staging
ORDER BY customer_id, customer_name;
