# Power BI — Reporting Layer (`SuperstoreDW.pbip`)

A **Power BI Project (PBIP)** that sits on top of the warehouse and delivers the
reporting layer: a star‑schema **semantic model** (tables, relationships, DAX
measures) plus a **Sales Overview** report page.

PBIP is the text‑based, Git‑friendly Power BI format — the semantic model is in
**TMDL** and the report in **PBIR**, so it version‑controls cleanly alongside the
SQL. (A binary `.pbix` is produced by *File → Save as → .pbix* in Power BI Desktop
once you've opened this project.)

> **Default source: PostgreSQL / Import** → `dw` schema of `dw_superstore` on
> `localhost`. Build the Postgres warehouse first (see [`/postgres`](../postgres)).

## What's inside

```
powerbi/
├─ SuperstoreDW.pbip                     ← open THIS in Power BI Desktop
├─ SuperstoreDW.SemanticModel/           ← the data model (TMDL)
│  └─ definition/
│     ├─ expressions.tmdl                ← DbSource: the DB connection (edit here)
│     ├─ model.tmdl / database.tmdl
│     ├─ relationships.tmdl              ← 5 fact→dim relationships
│     └─ tables/                         ← Date, Customer, Product, Geography,
│                                          Ship Mode, Sales (+ measures)
└─ SuperstoreDW.Report/                  ← the report (PBIR)
   └─ definition/pages/sales_overview/   ← 1 page, 8 visuals
```

### Semantic model
- **6 tables** = the star schema, with friendly names (`Sales` = the fact,
  `Date/Customer/Product/Geography/Ship Mode` = dimensions). Surrogate‑key
  columns are hidden; each dimension joins the fact on its key.
- **5 relationships**, all many‑to‑one, single direction (fact → dimension).
- **7 DAX measures** on `Sales`:

  | Measure | Definition |
  |---------|------------|
  | Total Sales | `SUM(Sales[Sales Amount])` |
  | Total Quantity | `SUM(Sales[Quantity])` |
  | Total Profit | `SUM(Sales[Profit])` |
  | Profit Margin % | `DIVIDE([Total Profit], [Total Sales])` |
  | Avg Discount | `AVERAGE(Sales[Discount])` |
  | Order Lines | `COUNTROWS(Sales)` |
  | Distinct Orders | `DISTINCTCOUNT(Sales[Order ID])` |

### Report — "Sales Overview" page
- 3 KPI cards: **Total Sales**, **Total Profit**, **Total Quantity**
- **Sales by Region** (clustered column)
- **Sales by Category** (clustered bar)
- **Sales by Segment** (donut)
- **Sales by Year** (line)
- **Year** slicer

These reproduce, in Power BI, the same questions the SQL `Cube*` views answer
(sales by region / category / segment / year — see
[`../docs/dimensional-model.md`](../docs/dimensional-model.md)).

## Prerequisites

1. **Power BI Desktop** (a 2024+ build) with **PBIP enabled**:
   *File → Options and settings → Options → Preview features →*
   ✅ *"Power BI Project (.pbip) save option"* (and, if listed, the
   *"Store semantic model / reports using TMDL/PBIR"* options). Restart Desktop.
2. **Npgsql** PostgreSQL provider — Power BI's PostgreSQL connector needs it.
   Install from the Npgsql releases (GAC install) if Desktop prompts.
3. The **Postgres warehouse built and loaded** (`/postgres/run_all.sql`).

## Open & refresh

1. Open `SuperstoreDW.pbip` in Power BI Desktop.
2. If your server/database differ from `localhost` / `dw_superstore`, edit the
   one line in `SemanticModel/definition/expressions.tmdl`:
   ```m
   Source = PostgreSQL.Database("localhost", "dw_superstore")
   ```
   (or change it in Desktop via *Transform data → DbSource*).
3. **Refresh** (Home → Refresh). Import mode pulls the data in; visuals populate.

> Until the first refresh, tables show no data and visuals say "can't display" —
> that's expected for an Import model shipped without cached data.

## Switching to SQL Server (the "do both" path)

The two warehouses use **different object and column names** (Postgres
`snake_case` in schema `dw`; SQL Server `PascalCase` in `dbo`), so one model
can't serve both unchanged. To repoint this model at SQL Server:

1. In `expressions.tmdl`, swap the connector:
   ```m
   Source = Sql.Database("localhost", "DW_Superstore")
   ```
2. In each `tables/*.tmdl` partition, change `Schema="dw"` → `Schema="dbo"` and
   the `Item` to the SQL Server table name (`dimCustomer`, `dimProduct`,
   `dimGeog`, `dimShipMode`, `dimDate`, `FACTOrderItem`).
3. Update each column's `sourceColumn` to the PascalCase name (e.g.
   `customer_segment` → `CustomerSegment`).

**Cleaner alternative (recommended if you truly want one report for both):**
create identical **compatibility views** in each database — e.g. `dw.pbi_sales`,
`dw.pbi_customer`, … in Postgres and `dbo.pbi_sales`, … in SQL Server — exposing
the *same* view and column names. Then only the connector + database name in
`DbSource` changes between engines; the tables, columns, measures, relationships
and every report visual stay identical. Happy to add these views on request.

## If the project won't open

**Error `Cannot find file 'version.json'` (Error Reading StorageSection:
ReportDocument):** the PBIR report package requires
`SuperstoreDW.Report/definition/version.json`. It is included here; if you ever
regenerate or move the report and hit this, recreate it with:
```json
{ "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/versionMetadata/1.0.0/schema.json", "version": "4.0" }
```

The semantic model (TMDL) is robust; the report visuals (PBIR) are the
schema‑strict part. If Desktop reports a problem opening the **report**:

- Open the **semantic model alone** — the model + measures still load, and you
  can drop the visuals onto a page yourself in minutes (the measures and fields
  are all there).
- Or delete `SuperstoreDW.Report/definition/pages/sales_overview/visuals/` and
  rebuild the visuals in Desktop.

The visual definitions here were authored to the PBIR spec but **could not be
validated in Power BI Desktop in this environment** — verify on first open.

## Add a screenshot

Once refreshed, capture the report and save it to [`/images`](../images), then
reference it from the root README to make the portfolio visual.
