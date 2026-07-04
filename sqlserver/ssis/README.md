# SSIS Implementation (SQL Server Integration Services)

This folder documents the **SSIS build** of the Superstore warehouse. The
runnable package itself is preserved in the archive:

- **Package:** [`../../archive/Day 3/Package.dtsx`](../../archive/Day%203/Package.dtsx)
- **Supporting T-SQL:** [`../../archive/Day 3/SQL/`](../../archive/Day%203/SQL)

> The SSIS package is **intentionally kept SQL Server–specific**. It is the
> visual/graphical ETL counterpart to the T-SQL build in this folder and remains
> fully functional. It is *not* being replaced — the PostgreSQL side documents
> equivalent orchestration options instead (see below).

## What the package does

The `Package.dtsx` control flow implements the same logical pipeline as the
T-SQL scripts:

1. **Create / reset** the `DW_Superstore_SSIS` database and staging table.
2. **Data Flow Task** — read the `Superstore` flat file / Excel source and load
   `SuperstoreStaging` (SSIS handles type conversion and error redirection).
3. **Execute SQL Tasks** — populate the dimensions, generate `dimDate`, then run
   the surrogate-key lookup to load `FACTOrderItem`.

The advantage of SSIS over a pure script is the **graphical data-flow designer**,
built-in **error-row redirection**, **logging/checkpoints**, and easy scheduling
via **SQL Server Agent**.

## Which parts stay SQL Server–specific?

| Component                     | Portable? | Notes |
|-------------------------------|-----------|-------|
| `.dtsx` package format        | ❌        | Proprietary to SSIS / Visual Studio (SSDT). |
| SSIS Data Flow / transforms   | ❌        | No native PostgreSQL equivalent runtime. |
| SQL Server Agent scheduling   | ❌        | Replaced by pgAgent / cron / Airflow on PG. |
| The T-SQL *logic* it executes | ✅        | Ported 1:1 to PostgreSQL under `/postgres`. |

## How the same workflow is done in the PostgreSQL ecosystem

See [`../../docs/ssis-and-orchestration.md`](../../docs/ssis-and-orchestration.md)
for the full mapping. In short:

| SSIS concept              | PostgreSQL-ecosystem equivalent |
|---------------------------|---------------------------------|
| Flat File Source → OLE DB | `\copy` / `COPY`, or Python (`pandas` + `psycopg2`) |
| Data Flow transforms      | SQL in the load scripts, or **dbt** models |
| Control Flow / precedence | **Apache Airflow** DAG, or a shell/PL/pgSQL driver |
| SQL Server Agent job      | **pgAgent** job, or **cron**, or Airflow scheduler |
| Package logging           | Airflow task logs / dbt run artifacts / PG logs |
