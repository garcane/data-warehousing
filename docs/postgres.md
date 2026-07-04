# Running the PostgreSQL Version

The PostgreSQL build is a functionally‑equivalent port of the SQL Server
reference. Scripts live in [`/postgres`](../postgres).

## Prerequisites

- **PostgreSQL 14 or later** (`generate_series`, `GENERATED ALWAYS AS IDENTITY`
  and `TRUNCATE … RESTART IDENTITY` all work on 12+; 14+ recommended).
- **`psql`** command‑line client (used for `\copy`, `\i`, `\echo`).
- The source file `Superstore.csv` reachable from where you run `psql`
  (default expects it in the `/postgres` folder — edit the path in
  `postgres/staging/02_load_staging.sql` otherwise).

### Option: run in Docker

```bash
docker run --name pg-dw -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
  -d postgres:16
```

## Build (two steps)

`CREATE DATABASE` cannot run inside the target database, so it is separate:

```bash
# 1. Create the database (connected to the default 'postgres' DB)
psql -U postgres -h localhost -f postgres/database/01_create_database.sql

# 2. Build everything inside it
cd postgres
psql -U postgres -h localhost -d dw_superstore -v ON_ERROR_STOP=1 -f run_all.sql
```

`run_all.sql` runs schemas → staging → warehouse DDL → loads → indexes → views →
procedure, echoing progress with `\echo`.

## Reload later

```sql
-- reload staging first (\i staging/02_load_staging.sql), then:
CALL dw.load_superstore_dw();
```

## Validate

```bash
psql -U postgres -d dw_superstore -f tests/postgres/validation.sql
psql -U postgres -d dw_superstore -f tests/postgres/quality-checks.sql
```

## Schema layout

Unlike the SQL Server build (everything in `dbo`), the PostgreSQL build separates
layers into schemas:

| Schema | Contents |
|--------|----------|
| `staging` | `superstore_staging` (raw landing) |
| `dw` | `dim_*`, `fact_order_item`, cube views, load procedure |

Query with either schema‑qualified names (`dw.fact_order_item`) or by setting
`search_path` (see `schemas/01_create_schemas.sql`).

## Key dialect differences you'll notice

- No `GO`; statements end at `;`. Use `\i` to include files, `\echo` to print.
- Surrogate keys use `GENERATED ALWAYS AS IDENTITY`.
- The calendar dimension is built with `generate_series` (no loop).
- Load procedure is called with `CALL`, not `EXEC`.
- Full details: [`migration-guide.md`](migration-guide.md).
