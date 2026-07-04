/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Presentation / Reporting
  Purpose : Cube views for BI consumption - functional equivalents of the SQL
            Server views. Naming preserved (cube0-3, mega_cube, v_customer_segment).
  ------------------------------------------------------------------------------
  Dialect note: PostgreSQL has no "IF NOT EXISTS" quirks here - CREATE OR REPLACE
  VIEW handles redefinition cleanly (SQL Server needs DROP + CREATE or
  CREATE OR ALTER).
==============================================================================*/

-- cube0 : daily sales by calendar attributes
CREATE OR REPLACE VIEW dw.cube0 AS
SELECT
    d.date_value,
    d.day, d.week, d.month, d.quarter, d.year,
    SUM(f.qty)   AS total_qty,
    SUM(f.sales) AS total_sales
FROM dw.fact_order_item AS f
    JOIN dw.dim_date AS d ON f.order_date_sk = d.date_sk
GROUP BY d.date_value, d.day, d.week, d.month, d.quarter, d.year;

-- cube1 : sales by customer, geography and quarter
CREATE OR REPLACE VIEW dw.cube1 AS
SELECT
    c.customer_sk, c.customer_name,
    g.region, g.state, g.city,
    d.year, d.quarter,
    SUM(f.qty)   AS total_qty,
    SUM(f.sales) AS total_sales
FROM dw.fact_order_item AS f
    JOIN dw.dim_customer AS c ON f.customer_sk   = c.customer_sk
    JOIN dw.dim_geog     AS g ON f.geog_sk       = g.geog_sk
    JOIN dw.dim_date     AS d ON f.order_date_sk = d.date_sk
GROUP BY c.customer_sk, c.customer_name, g.region, g.state, g.city, d.year, d.quarter;

-- cube2 : weekly sales by product category, customer segment and region
CREATE OR REPLACE VIEW dw.cube2 AS
SELECT
    d.year, d.week,
    p.product_category,
    c.customer_segment,
    g.region,
    SUM(f.qty)   AS total_qty,
    SUM(f.sales) AS total_sales
FROM dw.fact_order_item AS f
    JOIN dw.dim_date     AS d ON f.order_date_sk = d.date_sk
    JOIN dw.dim_product  AS p ON f.product_sk    = p.product_sk
    JOIN dw.dim_customer AS c ON f.customer_sk   = c.customer_sk
    JOIN dw.dim_geog     AS g ON f.geog_sk       = g.geog_sk
GROUP BY d.year, d.week, p.product_category, c.customer_segment, g.region;

-- cube3 : yearly sales by product category
CREATE OR REPLACE VIEW dw.cube3 AS
SELECT
    p.product_category,
    d.year,
    SUM(f.qty)   AS total_qty,
    SUM(f.sales) AS total_sales
FROM dw.fact_order_item AS f
    JOIN dw.dim_product AS p ON f.product_sk    = p.product_sk
    JOIN dw.dim_date    AS d ON f.order_date_sk = d.date_sk
GROUP BY p.product_category, d.year;

-- v_customer_segment : total sales per segment (LEFT JOIN keeps empty segments)
CREATE OR REPLACE VIEW dw.v_customer_segment AS
SELECT
    c.customer_segment,
    COALESCE(ROUND(SUM(f.sales)::numeric, 0), 0) AS total_sales
FROM dw.dim_customer AS c
    LEFT JOIN dw.fact_order_item AS f ON c.customer_sk = f.customer_sk
GROUP BY c.customer_segment;

-- mega_cube : grain-rich "answer everything" view
CREATE OR REPLACE VIEW dw.mega_cube AS
SELECT
    d.date_sk, d.year, d.month, d.week,
    g.geog_sk, g.region,
    p.product_sk, p.product_category, p.product_sub_category,
    c.customer_sk, c.customer_segment,
    SUM(f.sales)                  AS total_sales,
    SUM(f.qty)                    AS total_qty,
    SUM(f.profit)                 AS total_profit,
    AVG(f.discount::double precision) AS avg_discount,
    COUNT(*)                      AS transaction_count
FROM dw.fact_order_item AS f
    JOIN dw.dim_date     AS d ON f.order_date_sk = d.date_sk
    JOIN dw.dim_geog     AS g ON f.geog_sk       = g.geog_sk
    JOIN dw.dim_product  AS p ON f.product_sk    = p.product_sk
    JOIN dw.dim_customer AS c ON f.customer_sk   = c.customer_sk
GROUP BY
    d.date_sk, d.year, d.month, d.week,
    g.geog_sk, g.region,
    p.product_sk, p.product_category, p.product_sub_category,
    c.customer_sk, c.customer_segment;
