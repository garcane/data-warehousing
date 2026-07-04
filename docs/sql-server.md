# Running the SQL Server Version

The SQL Server build is the **reference implementation**. Scripts live in
[`/sqlserver`](../sqlserver).

## Prerequisites

- **SQL Server 2017 or later** (Developer or Express edition is fine). The
  original was built on SQL Server 2019 Express (`MSSQL15.SQLEXPRESS`).
- **SSMS** (SQL Server Management Studio) or **Azure Data Studio**, and/or the
  `sqlcmd` command‑line tool.
- The source file `Superstore.csv` placed at `C:\Superstore.csv`
  (see [`/sample-data`](../sample-data)). Edit the path in
  `sqlserver/staging/02_load_staging.sql` if you put it elsewhere.

### Option: run in Docker

```bash
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=YourStrong!Passw0rd' \
  -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```
Copy the CSV into the container (`docker cp Superstore.csv <id>:/Superstore.csv`)
and adjust the `BULK INSERT` path to `/Superstore.csv`.

## Build (SSMS)

Open and execute each script in this order (they are individually runnable):

```
sqlserver/database/01_create_database.sql
sqlserver/staging/01_create_staging.sql
sqlserver/staging/02_load_staging.sql
sqlserver/warehouse/01_create_dimensions.sql
sqlserver/warehouse/02_create_fact.sql
sqlserver/warehouse/03_load_dimensions.sql
sqlserver/warehouse/04_load_dimdate.sql
sqlserver/warehouse/05_load_fact.sql
sqlserver/indexes/01_indexes.sql
sqlserver/views/01_reporting_views.sql
sqlserver/procedures/usp_Load_SuperstoreDW.sql
```

`sqlserver/build_all.sql` documents this order and can be run in **SQLCMD Mode**
(Query → SQLCMD Mode in SSMS) or via `sqlcmd -i build_all.sql`.

## Reload later

Once built, reload staging then call the procedure:

```sql
-- reload staging first (staging/02_load_staging.sql), then:
EXEC dbo.usp_Load_SuperstoreDW;
```

## Validate

```
tests/sqlserver/validation.sql       -- PASS/FAIL row counts + reconciliation
tests/sqlserver/quality-checks.sql   -- duplicates / nulls / orphans / rules (expect 0 rows)
```

## Three build methods (history preserved)

The warehouse was originally built three ways; all are preserved in
[`/archive`](../archive):

| Method | Where | Notes |
|--------|-------|-------|
| Manual, step‑by‑step | `archive/Day 2` | Teaching version, built table by table |
| Automated T‑SQL script | `archive/Day 4`, `archive/Databases` | The basis for `/sqlserver` |
| **SSIS** graphical ETL | `archive/Day 3/Package.dtsx` | See [`ssis-and-orchestration.md`](ssis-and-orchestration.md) |
