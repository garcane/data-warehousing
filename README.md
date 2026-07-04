# Superstore Data Warehouse — SQL Server & PostgreSQL

> An end‑to‑end, Kimball‑style analytical **data warehouse** for retail sales,
> delivered on **Microsoft SQL Server** (reference implementation) **and**
> **PostgreSQL** (full port), with a documented ETL pipeline, dimensional model,
> data‑quality test suite, and cross‑platform migration guide.

<p align="center">
  <img src="architecture/star-schema.svg" alt="Superstore star schema" width="620">
</p>

---

## Executive summary

This project takes a raw retail sales extract (the 9,994‑row **Superstore**
dataset) and turns it into a **query‑optimised, dimensional data warehouse** that
business users can slice and dice through Power BI.

It demonstrates the full analytics‑engineering lifecycle: **source → staging →
conformed star schema → presentation views → reporting**, built with commercial
SQL standards (surrogate keys, referential integrity, transactional idempotent
loads, indexing) and validated by an automated **data‑quality test suite**.

The warehouse is implemented **twice** — on SQL Server (the reference) and on
PostgreSQL — to prove **cross‑platform SQL development** and to document every
dialect difference a migration would encounter.

| | |
|--|--|
| **Domain** | Retail sales analytics (OLAP) |
| **Model** | Kimball star schema — 1 fact + 5 conformed dimensions |
| **Grain** | One row per order line item |
| **Engines** | SQL Server 2017+ (reference) · PostgreSQL 14+ (port) |
| **ETL** | ELT: `BULK INSERT`/`\copy` → set‑based SQL → transactional load proc |
| **Orchestration** | SSIS (SQL Server) · dbt / Airflow / pgAgent (PostgreSQL) |
| **BI layer** | `Cube0–3`, `MegaCube`, `vCustomerSegment` views for Power BI |
| **Quality** | Row‑count, reconciliation, duplicate, null, orphan & rule checks |

## Business problem

An OLTP system is optimised for *writing* orders, not for *analysing* them.
Running heavy analytical queries against it is slow and competes with the
transactional workload. The solution is a separate **read‑optimised OLAP
warehouse** that stores sales history in a shape the business understands and
that BI tools can query fast.

Full write‑up: **[docs/business-problem.md](docs/business-problem.md)**.

## Architecture

A four/five‑layer flow — each layer has exactly one job:

```mermaid
flowchart LR
    A["Source<br/>Superstore.csv"] --> B["Staging<br/>raw, 1:1"]
    B --> C["Warehouse<br/>star schema"]
    C --> D["Presentation<br/>cube views"]
    D --> E["Reporting<br/>Power BI"]
```

<p align="center"><img src="architecture/pipeline.svg" alt="ETL pipeline" width="820"></p>

| Layer | Object(s) | Job |
|-------|-----------|-----|
| **Source** | `Superstore.csv` | System‑of‑record extract |
| **Staging** | `SuperstoreStaging` | Land raw data, minimal transformation |
| **Warehouse** | 5 `dim*` + `FACTOrderItem` | Conformed star schema, single source of truth |
| **Presentation** | `Cube0–3`, `MegaCube` | Pre‑joined/aggregated views |
| **Reporting** | Power BI, SQL clients | Consumption |

Details, lineage and key strategy: **[docs/architecture.md](docs/architecture.md)**.

## Technology stack

| Concern | SQL Server (reference) | PostgreSQL (port) |
|---------|------------------------|-------------------|
| Engine | SQL Server 2017+/2019 Express | PostgreSQL 14+ |
| Bulk load | `BULK INSERT` | `\copy` |
| Surrogate keys | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| Calendar build | recursive CTE / `WHILE` | `generate_series()` |
| Load procedure | `usp_Load_SuperstoreDW` (`TRY/CATCH`) | `dw.load_superstore_dw()` (`EXCEPTION`) |
| Graphical ETL | **SSIS** (`Package.dtsx`) | dbt / Airflow / pgAgent |
| Schemas | single `dbo` | layered `staging` + `dw` |
| BI | Power BI | Power BI |

## Warehouse layers & ETL pipeline

**ELT** — extract, load raw, then transform in‑database with set‑based SQL:

1. **Extract & load** the CSV into staging (`BULK INSERT` / `\copy`).
2. **Load dimensions** via `INSERT … SELECT DISTINCT` (surrogate keys auto‑assigned).
3. **Generate `dimDate`** across the order‑date range.
4. **Load the fact** with the **surrogate‑key pipeline** (join staging → each dim
   on the natural key to pick up the surrogate key).
5. **Index**, then publish **cube views**.

The whole transform is wrapped in a single **transactional, idempotent**
procedure. Full mechanics: **[docs/etl-process.md](docs/etl-process.md)**.

## Star schema

**One fact, five dimensions** (Kimball). See the diagram above and the full model
in **[docs/dimensional-model.md](docs/dimensional-model.md)**.

### Fact table — `FACTOrderItem`
- **Grain:** one row per **order line item** (9,994 rows).
- **Measures:** `Sales`, `Qty`, `Profit` (additive); `Discount` (a rate —
  average, don't sum).
- **Degenerate dimensions:** `Row_Id`, `Order_Id`.
- **Foreign keys** to all five dimensions enforce referential integrity.

### Dimension tables

| Dimension | Grain | Rows | Key attributes |
|-----------|-------|-----:|----------------|
| `dimDate` | calendar day | 1,458 | Day, Week, Month, Quarter, Year |
| `dimCustomer` | customer | 794 | Name, **Segment** |
| `dimProduct` | product | 1,894 | Category, Sub‑Category |
| `dimGeog` | location | 632 | Country, Region, State, City, PostalCode |
| `dimShipMode` | ship method | 4 | ShipMode |

Column‑level reference: **[docs/data-dictionary.md](docs/data-dictionary.md)**.

## Data flow (lineage)

```
Superstore.csv
  → SuperstoreStaging
      → dim{Customer,Product,Geog,ShipMode,Date}   (DISTINCT natural keys → surrogate keys)
      → FACTOrderItem                              (staging ⨝ dims on natural key → surrogate key)
          → Cube views → Power BI
```

## Project structure

```
data-warehousing/
├─ README.md                     ← you are here
├─ docs/                         business problem, architecture, model, ETL,
│                                 per‑engine guides, migration guide, data dictionary
├─ architecture/                 star‑schema & pipeline diagrams (SVG + draw.io)
├─ sqlserver/                    ◀ REFERENCE implementation (T‑SQL)
│  ├─ database/ staging/ warehouse/ indexes/ views/ procedures/ ssis/
│  └─ build_all.sql
├─ postgres/                     ◀ PostgreSQL port (staging + dw schemas)
│  ├─ database/ schemas/ staging/ warehouse/ indexes/ views/ procedures/
│  └─ run_all.sql
├─ powerbi/                      Power BI Project (PBIP): TMDL semantic model +
│                                 PBIR "Sales Overview" report (reporting layer)
├─ tests/                        data‑quality checks (SQL Server + PostgreSQL)
├─ sample-data/                  Superstore.csv + notes
├─ images/                       screenshots / exported visuals
└─ archive/                      original learning journal (Day 1–5) + SSMS scripts
                                 — preserved for reference; fully functional
```

## Running the SQL Server version

```
sqlserver/database/01_create_database.sql
sqlserver/staging/01_create_staging.sql → 02_load_staging.sql
sqlserver/warehouse/01…05 (dims, fact, loads, dimDate, fact load)
sqlserver/indexes/01_indexes.sql
sqlserver/views/01_reporting_views.sql
sqlserver/procedures/usp_Load_SuperstoreDW.sql
```
Place `Superstore.csv` at `C:\Superstore.csv` first. Full guide:
**[docs/sql-server.md](docs/sql-server.md)** · folder: [`/sqlserver`](sqlserver).

## Running the PostgreSQL version

```bash
psql -U postgres -f postgres/database/01_create_database.sql
cd postgres && psql -U postgres -d dw_superstore -v ON_ERROR_STOP=1 -f run_all.sql
```
Full guide: **[docs/postgres.md](docs/postgres.md)** · folder: [`/postgres`](postgres).

## Reporting (Power BI)

A **Power BI Project** in [`/powerbi`](powerbi) (`SuperstoreDW.pbip`) delivers the
reporting layer as version‑controlled text — a **TMDL** star‑schema semantic
model (6 tables, 5 relationships, 7 DAX measures) and a **PBIR** *Sales Overview*
report (KPI cards + sales by region / category / segment / year + a year slicer).
Default source is **PostgreSQL / Import**; the [Power BI README](powerbi/README.md)
covers enabling PBIP, refreshing, and repointing at SQL Server.

## Migration notes (SQL Server → PostgreSQL)

Every dialect difference is documented — identity vs generated columns,
`GETDATE()` vs `CURRENT_TIMESTAMP`, `ISNULL` vs `COALESCE`, `TOP` vs `LIMIT`,
`MERGE` alternatives, temp tables, string concatenation, date functions, stored
procedures, `BULK INSERT` vs `\copy`, clustered indexes, and SSIS equivalents —
in **[docs/migration-guide.md](docs/migration-guide.md)**.

Notable **documented behavioural difference:** week numbering (SQL Server
US‑style `DATEPART(WEEK)` vs PostgreSQL ISO‑8601 `EXTRACT(WEEK)`) can differ at
year boundaries.

## Data quality

Automated checks for **both** engines in [`/tests`](tests):

- **Row counts** vs the expected baseline (PASS/FAIL).
- **Reconciliation** — fact `SUM(Sales)` must equal staging `SUM(Sales)`.
- **Duplicates** — no duplicate natural keys in dimensions.
- **Nulls** — no null keys in the fact.
- **Referential integrity / orphans** — every fact key resolves to a dimension.
- **Business rules** — ship date ≥ order date, positive quantity, discount 0–1.

## Performance considerations

- **Indexing strategy:** OLAP favours *more* indexes than OLTP. Fact foreign‑key
  columns and dimension natural keys are indexed; the fact is `CLUSTER`ed
  (PostgreSQL) / clustered‑PK (SQL Server) on the most common scan path.
- **Load then index:** bulk‑load into an unindexed table, then build indexes once.
- **Set‑based everything:** the only original row‑by‑row step (the date loop) is
  replaced with a set‑based generator.
- **Pre‑aggregated views** shift repeated aggregation cost off report authors;
  they can be materialised if volumes grow.
- **Statistics:** `ANALYZE` (PostgreSQL) / auto‑stats (SQL Server) after load.

## Future improvements

- **Incremental / watermark loads** and **SCD Type 2** history (surrogate‑key
  design already supports it — see [docs/etl-process.md](docs/etl-process.md)).
- **dbt** models with built‑in tests as the transform layer.
- **Airflow** DAG for orchestration, retries and backfills.
- **Materialised views** for the heaviest cubes.
- **CI**: spin up a container, run the build, run `/tests`, fail on any non‑zero
  quality result.
- **Power BI** report(s) committed under `/images` to make the portfolio visual.

## Lessons learned

- **Declare the grain first.** "One row per order line item" drove every other
  decision; getting it explicit up front avoided ambiguous facts.
- **Surrogate keys pay off later.** They decouple the warehouse from volatile
  source keys and are what makes SCD‑2 a non‑breaking change.
- **Denormalise deliberately.** Folding `Segment` into `dimCustomer` breaks 3NF
  on purpose — fewer joins, faster reads. OLAP ≠ OLTP.
- **Reconcile, don't assume.** Comparing fact totals back to staging catches
  silent ETL errors that row counts alone miss.
- **Portability is a discipline.** Preferring ANSI SQL (`COALESCE`, `LIMIT`/
  `FETCH`, `||`) and isolating engine‑specific bits made the PostgreSQL port
  mechanical rather than a rewrite.

## Repository history

This started as a hands‑on learning project (the **Day 1–5** journal, now in
[`/archive`](archive)) covering OLAP vs OLTP, manual DW building, SSIS, cubes and
Power BI. That material is **preserved and still functional**; the top‑level
structure is the productionised, commercial version of it.

## License

[MIT](LICENSE). The Superstore sample data is synthetic and contains no real
personal data.
