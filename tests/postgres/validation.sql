/*==============================================================================
  Superstore DW  |  PostgreSQL  |  Tests: Row-count & structural validation
  Purpose : Confirm the build produced the expected shape (PASS/FAIL per check).
  Usage   : psql -d dw_superstore -f tests/postgres/validation.sql
==============================================================================*/

\echo '=== Row-count validation (expected baseline) ==='
WITH counts AS (
    SELECT 'staging.superstore_staging' AS object_name, count(*) AS actual_rows, 9994 AS expected_rows FROM staging.superstore_staging
    UNION ALL SELECT 'dw.dim_ship_mode',   count(*), 4    FROM dw.dim_ship_mode
    UNION ALL SELECT 'dw.dim_geog',        count(*), 632  FROM dw.dim_geog
    UNION ALL SELECT 'dw.dim_product',     count(*), 1894 FROM dw.dim_product
    UNION ALL SELECT 'dw.dim_customer',    count(*), 794  FROM dw.dim_customer
    UNION ALL SELECT 'dw.dim_date',        count(*), 1458 FROM dw.dim_date
    UNION ALL SELECT 'dw.fact_order_item', count(*), 9994 FROM dw.fact_order_item
)
SELECT
    object_name,
    expected_rows,
    actual_rows,
    CASE WHEN actual_rows = expected_rows THEN 'PASS' ELSE 'FAIL' END AS result
FROM counts
ORDER BY object_name;

\echo '=== Fact row count must equal staging row count ==='
SELECT
    (SELECT count(*) FROM staging.superstore_staging) AS staging_rows,
    (SELECT count(*) FROM dw.fact_order_item)         AS fact_rows,
    CASE WHEN (SELECT count(*) FROM staging.superstore_staging) = (SELECT count(*) FROM dw.fact_order_item)
         THEN 'PASS' ELSE 'FAIL' END AS result;

\echo '=== Measure totals reconcile staging vs fact ==='
SELECT
    round((SELECT sum(sales) FROM staging.superstore_staging)::numeric, 2) AS staging_sales,
    round((SELECT sum(sales) FROM dw.fact_order_item)::numeric, 2)         AS fact_sales,
    CASE WHEN round((SELECT sum(sales) FROM staging.superstore_staging)::numeric, 2)
            = round((SELECT sum(sales) FROM dw.fact_order_item)::numeric, 2)
         THEN 'PASS' ELSE 'FAIL' END AS result;
