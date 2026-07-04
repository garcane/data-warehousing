/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Warehouse (date dimension)
  Purpose : Generate one dim_date row per calendar day across the order range.
  Expected: 1458 rows (2014-01-01 .. 2017-12-31).
  ------------------------------------------------------------------------------
  Dialect win vs SQL Server:
    The original T-SQL used a WHILE loop (row-by-row) to build the calendar.
    PostgreSQL's generate_series() produces the whole range in ONE set-based
    statement - simpler, faster, and no recursion cap to lift.

  Date-part functions map as:
    DAY()          -> EXTRACT(DAY   FROM d)
    MONTH()        -> EXTRACT(MONTH FROM d)
    YEAR()         -> EXTRACT(YEAR  FROM d)
    DATEPART(WEEK) -> EXTRACT(WEEK  FROM d)     (ISO week; see note below)
    DATEPART(QUARTER) -> EXTRACT(QUARTER FROM d)
==============================================================================*/

TRUNCATE TABLE dw.dim_date RESTART IDENTITY CASCADE;

INSERT INTO dw.dim_date (date_value, day, week, month, quarter, year)
SELECT
    d::date                              AS date_value,
    EXTRACT(DAY     FROM d)::int         AS day,
    EXTRACT(WEEK    FROM d)::int         AS week,      -- ISO 8601 week number
    EXTRACT(MONTH   FROM d)::int         AS month,
    EXTRACT(QUARTER FROM d)::int         AS quarter,
    EXTRACT(YEAR    FROM d)::int         AS year
FROM generate_series(
        (SELECT min(order_date) FROM staging.superstore_staging),
        (SELECT max(order_date) FROM staging.superstore_staging),
        interval '1 day'
     ) AS d;

-- Validation: expect 1458.
SELECT count(*) AS dim_date_row_count FROM dw.dim_date;

/*  NOTE on week numbering:
    PostgreSQL EXTRACT(WEEK) returns the ISO-8601 week (1..53, week starts Mon).
    SQL Server DATEPART(WEEK) uses a US-style week (DATEFIRST/locale dependent).
    Weekly totals may therefore differ slightly at year boundaries between the
    two engines. This is a documented, expected dialect difference - see
    docs/migration-guide.md. Use EXTRACT(ISODOW)/ISO week consistently for
    portable weekly reporting.
*/
