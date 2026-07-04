# SQL Server → PostgreSQL Migration Guide

This is the practical reference for how the SQL Server (T‑SQL) reference
implementation was ported to PostgreSQL. Each section states the SQL Server way,
the PostgreSQL equivalent, and any behavioural caveat.

> **Golden rule of this project:** the SQL Server version is the *reference*. The
> PostgreSQL version is functionally equivalent; where exact behaviour cannot be
> reproduced, the difference is documented (not hidden).

## Quick data‑type map

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| `BIGINT`, `INT`, `SMALLINT` | `BIGINT`, `INTEGER`, `SMALLINT` | identical |
| `TINYINT` | `SMALLINT` | PG has no 1‑byte int |
| `BIT` | `BOOLEAN` | true/false vs 1/0 |
| `FLOAT` | `DOUBLE PRECISION` | 8‑byte float |
| `DECIMAL/NUMERIC(p,s)` | `NUMERIC(p,s)` | identical semantics |
| `CHAR(n)` / `VARCHAR(n)` | `CHAR(n)` / `VARCHAR(n)` | identical |
| `NVARCHAR(n)` | `VARCHAR(n)` / `TEXT` | PG text is Unicode by default; no separate `N` type |
| `DATE` | `DATE` | identical |
| `DATETIME2(7)` | `TIMESTAMP(6)` | **PG max fractional precision is 6**, not 7 |
| `UNIQUEIDENTIFIER` | `UUID` | (not used here) |

## Identity vs Serial vs Generated columns

- **SQL Server:** `Customer_SK BIGINT IDENTITY(1,1)`.
- **PostgreSQL (chosen here):** `customer_sk BIGINT GENERATED ALWAYS AS IDENTITY`
  — the SQL‑standard approach and the modern best practice.
- **`SERIAL`** is the older PostgreSQL idiom (`serial`/`bigserial`). It works but
  is discouraged for new schemas because it creates a loosely‑owned sequence and
  doesn't stop callers inserting explicit values. We use `GENERATED ALWAYS`.

To reseed on reload: SQL Server `TRUNCATE` reseeds automatically; PostgreSQL uses
`TRUNCATE … RESTART IDENTITY`.

## `GETDATE()` vs `CURRENT_TIMESTAMP`

| SQL Server | PostgreSQL |
|------------|------------|
| `GETDATE()`, `SYSDATETIME()` | `CURRENT_TIMESTAMP`, `now()` |
| `SYSUTCDATETIME()` | `now() AT TIME ZONE 'UTC'` |
| `CAST(GETDATE() AS DATE)` | `CURRENT_DATE` |

## `ISNULL` vs `COALESCE`

- `ISNULL(x, y)` is **SQL Server‑specific** and takes exactly two args.
- `COALESCE(x, y, …)` is **ANSI‑standard**, works on both engines, and takes many
  args. This project uses `COALESCE` throughout (e.g. `vCustomerSegment`).

## `TOP` vs `LIMIT`

| SQL Server | PostgreSQL |
|------------|------------|
| `SELECT TOP 5 * FROM t ORDER BY …` | `SELECT * FROM t ORDER BY … LIMIT 5` |
| `SELECT TOP 5 * … OFFSET/FETCH` | `… LIMIT 5 OFFSET n` |
| `OFFSET n ROWS FETCH NEXT 5 ROWS ONLY` | works on both (ANSI) |

## `MERGE` alternatives

SQL Server (and PG 15+) support `MERGE`. For portability and for PG < 15, the
idiomatic PostgreSQL upsert is `INSERT … ON CONFLICT`:

```sql
-- SQL Server
MERGE dim_x AS t USING src AS s ON t.nk = s.nk
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT (...) VALUES (...);

-- PostgreSQL (portable)
INSERT INTO dim_x (nk, attr) VALUES (...)
ON CONFLICT (nk) DO UPDATE SET attr = EXCLUDED.attr;
```

The current full‑refresh build uses neither (it truncates + reloads); `MERGE`
matters when you move to incremental/SCD‑2 loads.

## Temporary tables

| SQL Server | PostgreSQL |
|------------|------------|
| `#temp` (session), `##global` | `CREATE TEMP TABLE t (…)` (session‑scoped) |
| `SELECT … INTO #t` | `CREATE TEMP TABLE t AS SELECT …` |
| Table variables `@t` | no direct equivalent; use TEMP tables or CTEs |

## String concatenation

| SQL Server | PostgreSQL |
|------------|------------|
| `a + b` (strings) | `a || b` (ANSI) — **`+` does not concatenate in PG** |
| `CONCAT(a, b)` | `CONCAT(a, b)` (both) |
| `+` with a NULL → NULL | `||` with a NULL → NULL; use `CONCAT` to ignore NULLs |

## Date functions

| Purpose | SQL Server | PostgreSQL |
|---------|------------|------------|
| Year/Month/Day | `YEAR(d)`, `MONTH(d)`, `DAY(d)` | `EXTRACT(YEAR FROM d)`, … |
| Quarter | `DATEPART(QUARTER, d)` | `EXTRACT(QUARTER FROM d)` |
| Week | `DATEPART(WEEK, d)` | `EXTRACT(WEEK FROM d)` |
| Add days | `DATEADD(DAY, n, d)` | `d + n * interval '1 day'` |
| Difference | `DATEDIFF(DAY, a, b)` | `b - a` (returns integer days) |
| Generate a range | `WHILE` loop / recursive CTE | `generate_series(a, b, interval '1 day')` |

> ⚠️ **Week‑number caveat (documented behavioural difference).**
> `DATEPART(WEEK, …)` in SQL Server is US‑style and depends on `DATEFIRST`/locale,
> while PostgreSQL `EXTRACT(WEEK …)` is **ISO‑8601** (weeks start Monday, week 1
> contains the first Thursday). Weekly aggregates can therefore differ at
> year boundaries between the two builds. This is expected; for portable weekly
> reporting standardise on ISO week on both sides.

## Stored procedure differences

| | SQL Server | PostgreSQL |
|--|-----------|------------|
| Define | `CREATE PROCEDURE p AS BEGIN … END` | `CREATE PROCEDURE p() LANGUAGE plpgsql AS $$ … $$` |
| Call | `EXEC p` | `CALL p()` |
| Variables | `DECLARE @x INT` | `DECLARE x INT;` (in a `DECLARE` block) |
| Errors | `TRY/CATCH`, `THROW`, `RAISERROR` | `EXCEPTION WHEN … THEN`, `RAISE` |
| Print | `PRINT 'msg'` | `RAISE NOTICE 'msg'` |
| Result sets | procs can return rows implicitly | procs can't `SELECT`‑return; use functions (`RETURNS TABLE`) |

## Batch separators & scripting

| SQL Server | PostgreSQL |
|------------|------------|
| `GO` (SSMS/sqlcmd batch separator) | none — statements end at `;` |
| `USE db` | `\c db` (psql) |
| `:r file.sql` (SQLCMD include) | `\i file.sql` (psql include) |
| `PRINT` for progress | `\echo` (psql) or `RAISE NOTICE` |

## Bulk loading

| SQL Server | PostgreSQL |
|------------|------------|
| `BULK INSERT … FROM 'C:\file.csv'` (server‑side) | `\copy … FROM 'file.csv'` (client‑side, no superuser) or `COPY` (server‑side) |
| `SET DATEFORMAT dmy` | `SET datestyle = 'ISO, DMY'` |

## Clustered indexes

- **SQL Server:** every table here has a **clustered** PK — the table *is* the
  index, physically ordered by the key.
- **PostgreSQL:** has **no clustered indexes.** The PK is an ordinary b‑tree over
  a heap table. The nearest equivalent is `CLUSTER table USING index`, a **one‑off**
  physical reorder that is *not* maintained automatically. We `CLUSTER` the fact on
  the order‑date index because time‑range scans dominate.

## SSIS equivalents

SSIS (`.dtsx`) has no PostgreSQL runtime. See
[`ssis-and-orchestration.md`](ssis-and-orchestration.md) for the full mapping to
`\copy` / **dbt** / **Airflow** / **pgAgent** / Python ETL.
