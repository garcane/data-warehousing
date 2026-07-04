# SSIS & Orchestration

The original warehouse includes an **SSIS** (SQL Server Integration Services)
build — a graphical ETL package. It is **kept and remains SQL Server–specific**;
this document explains what stays SSIS‑only and how the *same* workflow is
achieved in the PostgreSQL ecosystem, **without replacing the SSIS package**.

- Package: [`/archive/Day 3/Package.dtsx`](../archive/Day%203/Package.dtsx)
- Notes: [`/sqlserver/ssis/README.md`](../sqlserver/ssis/README.md)

## What SSIS gives you

SSIS is a visual ETL tool (designed in Visual Studio / SSDT). Its `.dtsx` package
models the pipeline as a **Control Flow** of tasks, one of which is a **Data
Flow** (source → transforms → destination). Strengths:

- drag‑and‑drop **data‑flow designer** with typed columns;
- built‑in **error‑row redirection** (bad rows to a side table, not a crash);
- **logging, checkpoints, and restartability**;
- native scheduling via **SQL Server Agent**.

## What is SQL Server–specific (stays as‑is)

| Component | Portable? | Why |
|-----------|:---------:|-----|
| `.dtsx` package format | ❌ | Proprietary SSIS/SSDT artifact |
| Data Flow engine & transforms | ❌ | No PostgreSQL runtime executes `.dtsx` |
| SQL Server Agent jobs | ❌ | SQL Server scheduler |
| The **T‑SQL logic** inside the tasks | ✅ | Already ported to `/postgres` |

## Equivalent stacks in the PostgreSQL ecosystem

You don't replace SSIS with one tool — you assemble equivalents from the
open‑source data stack. Pick per need:

| SSIS concept | PostgreSQL‑ecosystem equivalent | When to use |
|--------------|--------------------------------|-------------|
| Flat‑File Source → destination (E+L) | **`\copy` / `COPY`** | Simple, fast CSV loads (what this repo uses) |
| Flat‑File Source (complex parsing) | **Python** (`pandas` + `psycopg2`/`SQLAlchemy`) | Messy files, APIs, custom logic |
| Data‑Flow transforms | **dbt** models (SQL `SELECT`s) | In‑warehouse transforms, tested & versioned |
| Control‑Flow / precedence constraints | **Apache Airflow** DAG | Dependencies, retries, backfills, monitoring |
| SQL Server Agent schedule | **pgAgent**, **cron**, or Airflow scheduler | Time‑based triggering |
| Package logging / checkpoints | Airflow task logs / dbt artifacts / PG logs | Observability |

### Minimal example: pgAgent / cron

Schedule the load procedure directly:

```bash
# crontab: reload the warehouse nightly at 02:00
0 2 * * *  psql -d dw_superstore -c "CALL dw.load_superstore_dw();"
```

### dbt shape (the modern "T" in ELT)

`\copy` lands raw data in `staging`; **dbt** then builds the dimensions and fact
as models with `ref()` dependencies and built‑in tests (`unique`, `not_null`,
`relationships`) — which map neatly onto this repo's `/tests` data‑quality checks.

### Airflow shape (orchestration)

```
extract_csv  >>  load_staging (\copy)  >>  call_load_proc (CALL dw.load_superstore_dw)  >>  run_quality_tests
```

Each box is an Airflow task; Airflow handles scheduling, retries, alerting and
backfills — the role SQL Server Agent plays for SSIS.

## Summary

- **SSIS stays** as the SQL Server graphical‑ETL reference.
- The PostgreSQL side reaches the same outcome with `\copy` + a transactional
  load procedure today, and scales to **dbt + Airflow + pgAgent** — the standard
  modern analytics‑engineering stack — when needed.
