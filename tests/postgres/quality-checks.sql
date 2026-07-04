/*==============================================================================
  Superstore DW  |  PostgreSQL  |  Tests: Data-quality checks
  Purpose : Duplicate detection, NULL checks, referential integrity, orphan
            detection, and business-rule sanity. Every query should return
            ZERO rows for a healthy warehouse.
  Usage   : psql -d dw_superstore -f tests/postgres/quality-checks.sql
==============================================================================*/

\echo '=== 1. Duplicate natural keys in dimensions (expect 0 rows each) ==='
SELECT 'dim_customer dup customer_id' AS check_name, customer_id, count(*)
FROM dw.dim_customer GROUP BY customer_id HAVING count(*) > 1;

SELECT 'dim_product dup product_id+name' AS check_name, product_id, product_name, count(*)
FROM dw.dim_product GROUP BY product_id, product_name HAVING count(*) > 1;

SELECT 'dim_ship_mode dup ship_mode' AS check_name, ship_mode, count(*)
FROM dw.dim_ship_mode GROUP BY ship_mode HAVING count(*) > 1;

SELECT 'dim_date dup date_value' AS check_name, date_value, count(*)
FROM dw.dim_date GROUP BY date_value HAVING count(*) > 1;

\echo '=== 2. NULLs in fact key columns (expect 0) ==='
SELECT count(*) AS null_key_rows
FROM dw.fact_order_item
WHERE customer_sk IS NULL OR product_sk IS NULL OR ship_mode_sk IS NULL
   OR geog_sk IS NULL OR order_date_sk IS NULL;

\echo '=== 3. Fact-to-dimension orphans (expect 0 rows each) ==='
SELECT 'orphan customer_sk' AS check_name, f.fact_sk
FROM dw.fact_order_item f LEFT JOIN dw.dim_customer d ON f.customer_sk = d.customer_sk
WHERE d.customer_sk IS NULL;

SELECT 'orphan product_sk' AS check_name, f.fact_sk
FROM dw.fact_order_item f LEFT JOIN dw.dim_product d ON f.product_sk = d.product_sk
WHERE d.product_sk IS NULL;

SELECT 'orphan geog_sk' AS check_name, f.fact_sk
FROM dw.fact_order_item f LEFT JOIN dw.dim_geog d ON f.geog_sk = d.geog_sk
WHERE d.geog_sk IS NULL;

SELECT 'orphan ship_mode_sk' AS check_name, f.fact_sk
FROM dw.fact_order_item f LEFT JOIN dw.dim_ship_mode d ON f.ship_mode_sk = d.ship_mode_sk
WHERE d.ship_mode_sk IS NULL;

SELECT 'orphan order_date_sk' AS check_name, f.fact_sk
FROM dw.fact_order_item f LEFT JOIN dw.dim_date d ON f.order_date_sk = d.date_sk
WHERE d.date_sk IS NULL;

\echo '=== 4. Business-rule sanity (expect 0 rows) ==='
SELECT 'ship_date < order_date' AS check_name, f.fact_sk, d.date_value AS order_date, f.ship_date
FROM dw.fact_order_item f JOIN dw.dim_date d ON f.order_date_sk = d.date_sk
WHERE f.ship_date < d.date_value;

SELECT 'non-positive qty' AS check_name, fact_sk, qty FROM dw.fact_order_item WHERE qty <= 0;

SELECT 'discount out of range' AS check_name, fact_sk, discount
FROM dw.fact_order_item WHERE discount < 0 OR discount > 1;

\echo '=== 5. Constraint verification (fact foreign keys should all be present) ==='
SELECT conname AS foreign_key, conrelid::regclass AS table_name
FROM pg_constraint
WHERE conrelid = 'dw.fact_order_item'::regclass AND contype = 'f'
ORDER BY conname;
