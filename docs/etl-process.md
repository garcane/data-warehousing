# ETL / ELT Process

## Overview

The load is a classic **ELT** (extract → load raw → transform in‑database):

```
Extract         Load (raw)            Transform (in the warehouse)
Superstore.csv → SuperstoreStaging → dimensions → dimDate → FACTOrderItem → cube views
```

Everything after staging is **set‑based SQL** running inside the database engine,
which is where relational engines are fastest.

## Step by step

### 1. Extract & Load to staging
- **SQL Server:** `BULK INSERT` from the CSV (`SET DATEFORMAT dmy` because source
  dates are dd/mm/yyyy).
- **PostgreSQL:** `\copy … WITH (FORMAT csv, HEADER true)` after `SET datestyle =
  'ISO, DMY'`.
- Staging mirrors the file 1:1 with **no transformation** — it's the safe
  re‑run/audit point.

### 2. Load dimensions (`INSERT … SELECT DISTINCT`)
Each dimension is the set of **distinct natural keys** from staging. Surrogate
keys are auto‑assigned by the identity column.

```sql
INSERT INTO dimShipMode (ShipMode)
SELECT DISTINCT Ship_Mode FROM SuperstoreStaging;
```

Expected: `dimShipMode=4, dimGeog=632, dimProduct=1894, dimCustomer=794`.

### 3. Generate the date dimension
- **SQL Server:** recursive CTE over `MIN(Order_Date)…MAX(Order_Date)` with
  `OPTION (MAXRECURSION 0)` (the original build used a `WHILE` loop — preserved in
  `/archive`).
- **PostgreSQL:** one set‑based `generate_series(min, max, interval '1 day')`.

Expected: `dimDate=1458` days (2014‑01‑01 … 2017‑12‑31).

### 4. Load the fact — the "surrogate‑key pipeline"
Join each staging row to every dimension on its **natural key** to pick up the
**surrogate key**, then insert:

```sql
INSERT INTO FACTOrderItem (...)
SELECT s.Row_ID, s.Order_ID, c.Customer_SK, p.Product_SK, m.ShipMode_SK,
       g.Geog_SK, d.Date_SK, s.Ship_Date, s.Sales, s.Quantity, s.Discount, s.Profit
FROM SuperstoreStaging s
  JOIN dimCustomer  c ON s.Customer_ID = c.CustomerId
  JOIN dimProduct   p ON s.Product_ID  = p.ProductId AND s.Product_Name = p.ProductName
  JOIN dimShipMode  m ON s.Ship_Mode   = m.ShipMode
  JOIN dimGeog      g ON s.Postal_Code = g.PostalCode AND s.City = g.City
  JOIN dimDate      d ON s.Order_Date  = d.DateValue;
```

Expected: `FACTOrderItem=9994` (equal to staging — nothing lost or duplicated).

### 5. Index, then publish views
Indexes are created **after** the bulk load (loading into an unindexed table is
faster, then one index build). Cube views sit on top for reporting.

## Orchestration & idempotency

Both engines wrap the whole transform in a **single, transactional procedure** so
a reload is one atomic call that rolls back cleanly on failure:

| | SQL Server | PostgreSQL |
|--|-----------|------------|
| Procedure | `EXEC dbo.usp_Load_SuperstoreDW` | `CALL dw.load_superstore_dw()` |
| Transaction safety | `SET XACT_ABORT ON` + `TRY/CATCH` + `THROW` | implicit txn + `EXCEPTION … RAISE` |
| Reset strategy | `DELETE` fact, `TRUNCATE` dims | `TRUNCATE … RESTART IDENTITY CASCADE` |

**Idempotent by design:** rerunning the build reproduces byte‑for‑byte the same
warehouse (surrogate keys reseed from 1). CI can apply it repeatedly.

## Current design: full refresh

The dataset is small, so each run **rebuilds from source** (SCD Type 1 /
truncate‑and‑reload). This is the simplest correct approach and keeps the project
easy to reason about.

## How this scales (documented, not yet implemented)

### Incremental / watermark loads
For large, growing sources you would switch from full refresh to incremental:

```
1) read last-loaded watermark from a control table
2) select source rows where updated_at > watermark
3) load into staging, transform
4) MERGE/UPSERT into targets
5) update the watermark + write a load-audit record
```

### Slowly Changing Dimensions
Upgrade a dimension to **Type 2** to keep history:

```sql
-- when a tracked attribute changes:
--   expire the current row (end_date, current_flag = 0)
--   insert a new row (new surrogate key, current_flag = 1)
```

The fact always joins on surrogate keys, so Type‑2 history is a non‑breaking add.
On SQL Server this is naturally expressed with `MERGE`; PostgreSQL uses
`INSERT … ON CONFLICT` or a two‑statement upsert (see
[`migration-guide.md`](migration-guide.md#merge-alternatives)).

### Error handling & auditing
At scale, add an **audit/error table** capturing rows that fail dimension lookups
(e.g. a fact row whose product isn't in `dimProduct`), rather than silently
dropping them via `INNER JOIN`. The data‑quality tests in [`/tests`](../tests)
already detect orphans after the fact.
