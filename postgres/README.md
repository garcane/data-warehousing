# PostgreSQL Implementation

A complete, functionally-equivalent port of the SQL Server reference warehouse
to **PostgreSQL** (tested against PostgreSQL 14+). The star schema, grain,
measures and reporting views are identical; only dialect-specific syntax and a
few deliberate improvements differ.

> **The SQL Server version remains the reference implementation.** This port is
> additive — see [`/docs/migration-guide.md`](../docs/migration-guide.md) for a
> line-by-line dialect comparison and [`/docs/postgres.md`](../docs/postgres.md)
> for setup details.

## Deliberate improvements over the SQL Server build

| Area                | SQL Server              | PostgreSQL (here)                         |
|---------------------|-------------------------|-------------------------------------------|
| Layer separation    | single `dbo` schema     | `staging` + `dw` schemas                   |
| Surrogate keys      | `IDENTITY(1,1)`         | `GENERATED ALWAYS AS IDENTITY` (SQL std)   |
| Calendar build      | `WHILE` loop            | set-based `generate_series()`              |
| Load procedure      | `TRY/CATCH` + `THROW`   | PL/pgSQL `EXCEPTION` block + `RAISE`        |

## Folder layout

| Folder        | Contents |
|---------------|----------|
| `database/`   | Create the `dw_superstore` database. |
| `schemas/`    | Create `staging` and `dw` schemas. |
| `staging/`    | Staging table + `\copy` load from the CSV. |
| `warehouse/`  | Dimension & fact DDL, dimension/date/fact loads. |
| `indexes/`    | B-tree indexes + `CLUSTER` + `ANALYZE`. |
| `views/`      | Presentation-layer cube views. |
| `procedures/` | `dw.load_superstore_dw()` — transactional full reload. |
| `run_all.sql` | Orchestrates the whole build. |

## Quick start

```bash
# 1. Create the database (connected to the default postgres DB)
psql -U postgres -f database/01_create_database.sql

# 2. Build everything inside it (place Superstore.csv in this folder first,
#    or edit the path in staging/02_load_staging.sql)
psql -U postgres -d dw_superstore -v ON_ERROR_STOP=1 -f run_all.sql

# 3. Validate
psql -U postgres -d dw_superstore -f ../tests/postgres/validation.sql
```

## Expected row counts

| Object                       | Rows  |
|------------------------------|-------|
| staging.superstore_staging   | 9,994 |
| dw.dim_ship_mode             | 4     |
| dw.dim_geog                  | 632   |
| dw.dim_product               | 1,894 |
| dw.dim_customer              | 794   |
| dw.dim_date                  | 1,458 |
| dw.fact_order_item           | 9,994 |
