/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (fact load)
  Purpose : Load dw.fact_order_item via the surrogate-key pipeline (resolve each
            staging row's natural keys to dimension surrogate keys).
  Grain   : One row per order line item.  Expected: 9994 rows.
  ------------------------------------------------------------------------------
  This is a direct, functionally-identical port of the SQL Server fact load.
  The join predicates match the natural keys used when the dimensions were built.
==============================================================================*/

TRUNCATE TABLE dw.fact_order_item RESTART IDENTITY;

INSERT INTO dw.fact_order_item (
    row_id, order_id, customer_sk, product_sk, ship_mode_sk, geog_sk,
    order_date_sk, ship_date, sales, qty, discount, profit
)
SELECT
    s.row_id,
    s.order_id,
    c.customer_sk,
    p.product_sk,
    m.ship_mode_sk,
    g.geog_sk,
    d.date_sk,
    s.ship_date,
    s.sales,
    s.quantity,
    s.discount,
    s.profit
FROM staging.superstore_staging AS s
    JOIN dw.dim_customer  AS c ON s.customer_id = c.customer_id
    JOIN dw.dim_product   AS p ON s.product_id  = p.product_id  AND s.product_name = p.product_name
    JOIN dw.dim_ship_mode AS m ON s.ship_mode   = m.ship_mode
    JOIN dw.dim_geog      AS g ON s.postal_code = g.postal_code AND s.city = g.city
    JOIN dw.dim_date      AS d ON s.order_date  = d.date_value;

-- Validation: expect 9994.
SELECT count(*) AS fact_row_count FROM dw.fact_order_item;
