# Data Warehousing

Centralized examples, patterns, and utilities for building and maintaining analytical data warehouses using SQL and T-SQL.

This repository collects reusable SQL code, data modeling notes, ETL patterns, and operational guidance for building reliable, performant data warehouses.

## Contents

- `ddl/` — Example DDL for dimensional and staging schemas (tables, indexes, constraints).
- `etl/` — ETL/ELT scripts and stored procedure patterns.
- `sql/` — Reusable query snippets, aggregation patterns, and performance tips.
- `docs/` — Design notes, modeling guidelines, and runbooks.

> **Language composition:** 95.7% SQL, 4.3% T-SQL (procedural extensions for SQL Server).

## Goals

- Provide clear, production-ready SQL patterns for staging, transformation, and reporting layers.
- Document dimensional modeling and best practices for performance and maintainability.
- Share operational guidance for incremental loads, error handling, and deployment.

## Architecture & Patterns

### Canonical Layered Architecture

The assets in this repository follow a proven four-layer architecture:

1. **Raw ingestion (landing/staging):** Minimal transformation, preserve source fidelity.
2. **Staging:** Light cleansing, type conversions, and surrogate key lookups.
3. **Conformed dimensions & facts:** Canonical dimensional models (star schema).
4. **Aggregate & reporting layer:** Materialized aggregates, views, and export-ready tables.

### Recommended Patterns

This repository includes implementations of:

- **Slowly Changing Dimensions (SCD)** — Type 1 and Type 2 examples
- **Merge-based upserts** — Using `MERGE` or idempotent `INSERT`/`UPDATE` flows
- **Date/time dimensions** — Generation and time-windowed incremental loading
- **Error handling** — Audit/error tables and consistent logging patterns

## Quick Examples

### Dimension Table DDL

```sql
CREATE TABLE dim_customer (
  customer_sk INT IDENTITY(1,1) PRIMARY KEY,
  customer_id VARCHAR(100) NOT NULL,
  customer_name VARCHAR(400),
  email VARCHAR(255),
  current_flag BIT NOT NULL DEFAULT 1,
  effective_date DATE NOT NULL,
  end_date DATE NULL,
  load_datetime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
```

### Merge/Upsert Pattern (T-SQL)

```sql
MERGE INTO dbo.dim_customer AS target
USING (SELECT customer_id, customer_name, email FROM staging.customer) AS src
ON target.customer_id = src.customer_id
WHEN MATCHED AND (target.customer_name <> src.customer_name OR target.email <> src.email)
  THEN UPDATE SET target.current_flag = 0, target.end_date = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET
  THEN INSERT (customer_id, customer_name, email, effective_date, load_datetime)
       VALUES (src.customer_id, src.customer_name, src.email, CONVERT(date, SYSUTCDATETIME()), SYSUTCDATETIME());
```

### Incremental Load Workflow

```sql
-- 1) Get max loaded watermark from control table
-- 2) Select source rows where updated_at > watermark
-- 3) Load into staging, apply transformations
-- 4) Upsert into target using MERGE
-- 5) Update watermark and write load audit record
```

## Getting Started

### Local Setup

1. **Create a local SQL Server instance** (or use Docker):
   ```bash
   docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=YourPassword123' \
     -p 1433:1433 -d mcr.microsoft.com/mssql/server
   ```

2. **Run the provided DDL** from `ddl/` to create schemas and tables.

3. **Load sample data** from CSV files into staging and run ETL scripts in `etl/`.

### Using Examples in Your Projects

- Browse `ddl/` and `etl/` for runnable examples you can adapt to your environment.
- Copy proven patterns into your CI/CD pipelines; prefer idempotent scripts for safe re-runs.
- Refer to `docs/` for design decisions and runbooks before and after major changes.

## Testing & Validation

- **Keep scripts idempotent** — CI should apply them repeatedly without errors.
- **Add unit tests** — Use tSQLt for SQL Server testing.
- **Validate data quality** — Include row-count assertions and data validation checks in pipeline tests.

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Open an issue** describing your proposed change or addition.
2. **Create a topic branch** and open a pull request with:
   - A clear description of the change
   - Test instructions and validation steps
3. **Keep examples small and portable:**
   - Include clear DDL and sample data for reproduction
   - Add comments explaining assumptions and environment requirements
   - Minimize vendor-specific features; document if required

## Security & Data Sensitivity

⚠️ **Important:** This repository should not contain:
- Production data or credentials
- Sensitive information or customer data
- Database connection strings or secrets

All sample data must be synthetic. If you add scripts that connect to databases, ensure credentials are sourced from secure secrets management tools.

## License

No license is currently specified. A LICENSE file should be added to declare usage terms. Consider using an open-source license like MIT, Apache 2.0, or GPL.

## Contact & Requests

**Maintainer:** [@garcane](https://github.com/garcane)

Have a specific request? Please open an issue with details about:
- **Target engine:** SQL Server T-SQL, PostgreSQL, BigQuery, etc.
- **Use case:** SCD2 implementation, full ETL pipeline, CI/CD pipeline examples, etc.

Looking forward to your contributions!
