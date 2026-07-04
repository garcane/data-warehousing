/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (orchestration)
  Object  : dw.load_superstore_dw()  (PL/pgSQL PROCEDURE)
  Purpose : One-call, transactionally-safe full reload of the warehouse from an
            already-populated staging.superstore_staging table.
  ------------------------------------------------------------------------------
  Dialect mapping vs SQL Server (see docs/migration-guide.md):
    CREATE PROCEDURE ... AS BEGIN ... END        -> CREATE PROCEDURE ... LANGUAGE plpgsql AS $$ ... $$
    T-SQL error handling: BEGIN TRY / CATCH / THROW
      -> PL/pgSQL: BEGIN ... EXCEPTION WHEN OTHERS THEN ... RAISE
    Transaction: a PROCEDURE body runs in the caller's transaction by default.
      When invoked with CALL (and no surrounding explicit txn), the whole body is
      one atomic unit - any exception rolls it all back automatically. We add an
      explicit EXCEPTION block to log context and re-raise.
  Usage   : CALL dw.load_superstore_dw();
==============================================================================*/

CREATE OR REPLACE PROCEDURE dw.load_superstore_dw()
LANGUAGE plpgsql
AS $$
BEGIN
    ------------------------------------------------------------------
    -- 1. Reset targets. RESTART IDENTITY reseeds surrogate keys to 1.
    --    CASCADE also empties fact_order_item (FK child).
    ------------------------------------------------------------------
    TRUNCATE TABLE
        dw.fact_order_item,
        dw.dim_ship_mode,
        dw.dim_geog,
        dw.dim_product,
        dw.dim_customer,
        dw.dim_date
    RESTART IDENTITY CASCADE;

    ------------------------------------------------------------------
    -- 2. Load conformed dimensions.
    ------------------------------------------------------------------
    INSERT INTO dw.dim_ship_mode (ship_mode)
    SELECT DISTINCT ship_mode FROM staging.superstore_staging;

    INSERT INTO dw.dim_geog (country, region, state, city, postal_code)
    SELECT DISTINCT country, region, state, city, postal_code FROM staging.superstore_staging;

    INSERT INTO dw.dim_product (product_id, product_name, product_category, product_sub_category)
    SELECT DISTINCT product_id, product_name, category, sub_category FROM staging.superstore_staging;

    INSERT INTO dw.dim_customer (customer_id, customer_name, customer_segment)
    SELECT DISTINCT customer_id, customer_name, segment FROM staging.superstore_staging;

    ------------------------------------------------------------------
    -- 3. Generate the calendar dimension (set-based generate_series).
    ------------------------------------------------------------------
    INSERT INTO dw.dim_date (date_value, day, week, month, quarter, year)
    SELECT
        d::date,
        EXTRACT(DAY     FROM d)::int,
        EXTRACT(WEEK    FROM d)::int,
        EXTRACT(MONTH   FROM d)::int,
        EXTRACT(QUARTER FROM d)::int,
        EXTRACT(YEAR    FROM d)::int
    FROM generate_series(
            (SELECT min(order_date) FROM staging.superstore_staging),
            (SELECT max(order_date) FROM staging.superstore_staging),
            interval '1 day'
         ) AS d;

    ------------------------------------------------------------------
    -- 4. Load the fact via the surrogate-key pipeline.
    ------------------------------------------------------------------
    INSERT INTO dw.fact_order_item (
        row_id, order_id, customer_sk, product_sk, ship_mode_sk, geog_sk,
        order_date_sk, ship_date, sales, qty, discount, profit
    )
    SELECT
        s.row_id, s.order_id, c.customer_sk, p.product_sk, m.ship_mode_sk,
        g.geog_sk, d.date_sk, s.ship_date, s.sales, s.quantity, s.discount, s.profit
    FROM staging.superstore_staging AS s
        JOIN dw.dim_customer  AS c ON s.customer_id = c.customer_id
        JOIN dw.dim_product   AS p ON s.product_id  = p.product_id  AND s.product_name = p.product_name
        JOIN dw.dim_ship_mode AS m ON s.ship_mode   = m.ship_mode
        JOIN dw.dim_geog      AS g ON s.postal_code = g.postal_code AND s.city = g.city
        JOIN dw.dim_date      AS d ON s.order_date  = d.date_value;

    RAISE NOTICE 'load_superstore_dw: warehouse reloaded successfully.';
EXCEPTION
    WHEN OTHERS THEN
        -- The failed transaction is rolled back automatically; re-raise so the
        -- caller / scheduler sees the failure with full context.
        RAISE EXCEPTION 'load_superstore_dw FAILED: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END;
$$;
