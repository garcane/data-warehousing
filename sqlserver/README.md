# SQL Server Implementation (Reference)

This is the **reference implementation** of the Superstore data warehouse, on
Microsoft SQL Server (developed originally on SQL Server 2019 Express). Every
object here is the cleaned, commented, commercial version of the scripts in
[`/archive`](../archive).

## Folder layout

| Folder        | Contents |
|---------------|----------|
| `database/`   | Create the `DW_Superstore` database. |
| `staging/`    | Staging (landing) table + bulk load from the CSV. |
| `warehouse/`  | Dimension & fact DDL, dimension/date/fact loads. |
| `indexes/`    | Non-clustered indexes for star-join performance. |
| `views/`      | Presentation-layer "cube" views for Power BI. |
| `procedures/` | `usp_Load_SuperstoreDW` — transactional full reload. |
| `ssis/`       | Notes on the preserved SSIS package (graphical ETL). |
| `build_all.sql` | Documents the full run order. |

## Prerequisites

- SQL Server 2017+ (Express is fine) and SSMS or `sqlcmd`.
- `Superstore.csv` placed at `C:\Superstore.csv` (see [`/sample-data`](../sample-data)),
  or edit the path in `staging/02_load_staging.sql`.

## Run order

```
database/01_create_database.sql
staging/01_create_staging.sql
staging/02_load_staging.sql        -- BULK INSERT the CSV
warehouse/01_create_dimensions.sql
warehouse/02_create_fact.sql
warehouse/03_load_dimensions.sql
warehouse/04_load_dimdate.sql
warehouse/05_load_fact.sql
indexes/01_indexes.sql
views/01_reporting_views.sql
procedures/usp_Load_SuperstoreDW.sql
```

Then validate with the scripts in [`/tests/sqlserver`](../tests/sqlserver).

## Expected row counts (data quality baseline)

| Object            | Rows  |
|-------------------|-------|
| SuperstoreStaging | 9,994 |
| dimShipMode       | 4     |
| dimGeog           | 632   |
| dimProduct        | 1,894 |
| dimCustomer       | 794   |
| dimDate           | 1,458 |
| FACTOrderItem     | 9,994 |
