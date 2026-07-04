# Tests & Data Quality

Two kinds of checks, provided for **both** engines so the warehouses can be
validated identically.

| File | What it does |
|------|--------------|
| `*/validation.sql`     | Row counts vs the expected baseline, staging↔fact reconciliation, and measure-total reconciliation. Prints **PASS/FAIL** per check. |
| `*/quality-checks.sql` | Duplicate natural keys, NULL key columns, fact-to-dimension **orphans**, business-rule sanity (ship ≥ order date, positive qty, discount 0–1), and constraint verification. Every query should return **zero rows**. |

## Run

**SQL Server** (in SSMS against `DW_Superstore`, or via sqlcmd):
```
sqlserver → tests/sqlserver/validation.sql
           tests/sqlserver/quality-checks.sql
```

**PostgreSQL:**
```bash
psql -U postgres -d dw_superstore -f tests/postgres/validation.sql
psql -U postgres -d dw_superstore -f tests/postgres/quality-checks.sql
```

## Expected baseline

| Object | Rows |
|--------|------|
| staging | 9,994 |
| dim_ship_mode | 4 |
| dim_geog | 632 |
| dim_product | 1,894 |
| dim_customer | 794 |
| dim_date | 1,458 |
| fact_order_item | 9,994 |

## What "good" looks like
- Every row-count check reports **PASS**.
- Every quality query returns **0 rows** (no duplicates / NULLs / orphans / rule breaks).
- Fact `SUM(Sales)` reconciles to staging `SUM(Sales)` to 2 dp.
