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

### Overview

A **Power BI Project** in [`/powerbi`](powerbi) (`SuperstoreDW.pbip`) delivers the
reporting layer as **Git‑friendly, version‑controlled text** — a **TMDL** 
star‑schema semantic model (6 tables, 5 relationships, 7 DAX measures) and a 
**PBIR** multi‑page report. The PBIP format keeps the semantic model and report 
definitions in human‑readable markup (not binary), integrating cleanly with the 
SQL version control.

**Default source:** PostgreSQL / Import mode against the `dw` schema of 
`dw_superstore` on `localhost`. The model can be repointed to SQL Server by 
editing one connection line (see [Power BI README](powerbi/README.md)).

### What the Report Answers

The **SuperstoreDW Sales Dashboard** addresses the core commercial questions every 
retail business needs answered:

| Business Question | Report Page(s) | What It Reveals |
|---|---|---|
| **Revenue health & profitability** | Executive Summary, Profitability Deep Dive | Total sales, profit, and margin trend; which product categories and regions drive profit vs. volume |
| **Geographic performance** | Executive Summary, Regional Performance | Sales by region and state; which geographies are most profitable; regional margin variance |
| **Customer mix & volume** | Customer Segmentation | Customer segment distribution; order count vs. line-item count; product mix by category and sub-category |
| **Product strategy** | Product Profitability | High‑margin vs. loss‑making products; top and bottom performers by sub‑category; category profitability spread |
| **Discount impact** | Regional Performance, Profitability Deep Dive | How discounting varies by region and product; the discount↔margin trade‑off |
| **Shipping efficiency** | Operations & Shipping | Order and volume distribution across Standard/First Class/Same Day; discount and cost by shipping mode |
| **Trends over time** | Sales Performance, Profitability Deep Dive | Revenue trajectory 2014–2017; profit margin evolution; seasonal and year‑over‑year patterns |

### Semantic Model

**Six tables** — the conformed star schema with surrogate keys, hidden to the 
report layer:

| Table | Type | Rows | Role | Joins |
|---|---|---|---|---|
| **Sales** | Fact | 9,994 | Order line items; additive measures | ← all dimensions |
| **Customer** | Dimension | 794 | Customer IDs, names, segments | → fact |
| **Product** | Dimension | 1,894 | Product IDs, names, categories, sub‑categories | → fact |
| **Geography** | Dimension | 632 | Countries, regions, states, cities | → fact |
| **Ship Mode** | Dimension | 4 | Standard Class, First Class, Second Class, Same Day | → fact |
| **Date** | Dimension | 1,458 | Calendar 3 Jan 2014 – 30 Dec 2017; day/week/month/quarter/year attributes | → fact |

**Five relationships** — all many‑to‑one (fact → dimension), single direction, 
on integer surrogate keys.

### Key Measures

**Seven global DAX measures** on the `Sales` fact table, all reusable across 
every page:

| Measure | Formula | Business Value |
|---|---|---|
| **Total Sales** | `SUM(Sales[Sales Amount])` | Revenue ($) |
| **Total Profit** | `SUM(Sales[Profit])` | Bottom‑line result ($) |
| **Profit Margin %** | `DIVIDE([Total Profit], [Total Sales])` | Efficiency — what % of revenue becomes profit |
| **Total Quantity** | `SUM(Sales[Quantity])` | Volume (units) |
| **Avg Discount** | `AVERAGE(Sales[Discount])` | Average discount rate; tracked because it erodes margin |
| **Order Lines** | `COUNTROWS(Sales)` | Operational load (transactions to fulfil) |
| **Distinct Orders** | `DISTINCTCOUNT(Sales[Order ID])` | Customer transaction count (5,010 orders from 9,994 line items) |

### Report Structure

**Pages 1:**
- **Executive Summary** — KPI cards (sales, profit, margin, quantity), regional 
  map, sales by category and ship mode, region and date slicers.

<p align="center">
  <img src="powerbi/SuperstoreDW (1).png" alt="Executive Summary page — KPIs, regional map, sales by category and ship mode" width="760">
</p>

**Pages 2:**
- **Customer Segmentation & Volume** — order/line KPIs, customer segment 
  distribution, product count by category, orders by category and ship mode.

<p align="center">
  <img src="powerbi/SuperstoreDW (2).png" alt="Customer Segmentation & Volume page — segment distribution, product mix" width="760">
</p>

**Pages 3:**
- **Sales Performance & Trends** — sales by region, quantity by region, monthly 
  sales trend line.

<p align="center">
  <img src="powerbi/SuperstoreDW (3).png" alt="Sales Performance & Trends page — regional sales analysis and trend line" width="760">
</p>

**Pages 4:**
- **Product Profitability** — sales/profit by category, top/bottom 5 
  sub‑categories by profit.

<p align="center">
  <img src="powerbi/SuperstoreDW (4).png" alt="Product Profitability page — category and sub-category performance" width="760">
</p>

**Pages 5:**
- **Regional Performance & Margins** — orders and avg discount by region, 
  profit margin by region, state‑level sales.

<p align="center">
  <img src="powerbi/SuperstoreDW (5).png" alt="Regional Performance & Margins page — region comparison, discount and margin analysis" width="760">
</p>

**Pages 6:**
- **Operations & Shipping Efficiency** — order/quantity by shipping mode, 
  discount by mode, sales by category & ship mode cross‑tab.

<p align="center">
  <img src="powerbi/SuperstoreDW (6).png" alt="Operations & Shipping page — shipping mode analysis and logistics efficiency" width="760">
</p>

**Pages 7:**
- **Profitability Deep Dive** — margin by category, profit vs. discount 
  scatter (by sub‑category), profit trend over time.

<p align="center">
  <img src="powerbi/SuperstoreDW (7).png" alt="Profitability Deep Dive page — margin trends, discount impact, profit analysis" width="760">
</p>

### Connection & Refresh

1. **Open** `SuperstoreDW.pbip` in Power BI Desktop (2024+ with PBIP preview enabled).
2. **Set the source** (if not `localhost`/`dw_superstore`): edit 
   `SemanticModel/definition/expressions.tmdl`, line 1 (`DbSource`).
3. **Refresh** — Import mode pulls all six tables and caches them.
4. **Verify** — visuals populate; benchmarks in the specification document 
   validate the load (e.g. Total Sales should be $2,297,201).

Full setup guide: **[Power BI README](powerbi/README.md)** · 
Specification: **[SuperstoreDW Sales Dashboard Specification](powerbi/SuperstoreDW_Sales_Dashboard_Specification_v2.0.html)**.

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
