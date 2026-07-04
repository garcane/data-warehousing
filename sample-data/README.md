# Sample Data

## `Superstore.csv`

The **Superstore** sample dataset — the source feed for the warehouse.

| Property | Value |
|----------|-------|
| Rows | 9,994 (+ 1 header) |
| Columns | 21 |
| Delimiter | comma (`,`), quoted fields |
| Date format | `dd/mm/yyyy` |
| Period | 2014‑01‑01 → 2017‑12‑31 |
| Scope | United States retail orders |

It is a well‑known, widely‑used **synthetic** teaching dataset (originally
distributed with Tableau). It contains **no real customers, PII, or credentials**
— safe to commit.

## How the builds consume it

- **SQL Server** — `BULK INSERT` expects it at `C:\Superstore.csv` by default.
  Copy it there, or edit the path in
  [`../sqlserver/staging/02_load_staging.sql`](../sqlserver/staging/02_load_staging.sql).
- **PostgreSQL** — `\copy` reads it relative to where you run `psql` (default:
  the `/postgres` folder). Copy it there, or edit the path in
  [`../postgres/staging/02_load_staging.sql`](../postgres/staging/02_load_staging.sql).

```bash
# SQL Server (Windows)
copy sample-data\Superstore.csv C:\Superstore.csv

# PostgreSQL
cp sample-data/Superstore.csv postgres/Superstore.csv
```

## Other source files (in the archive)

- `archive/Day 3/data/Superstore.xls` — Excel copy used by the SSIS build.
- `archive/Day 4/Superstore.csv` — tab‑delimited variant (`Superstore.txt`
  style) used by the automated T‑SQL build's `BULK INSERT`.
- `archive/Day 1/data/Sales.txt` — source for the separate `DW_Sales` exercise.

## Column reference

See the full [data dictionary](../docs/data-dictionary.md#staging--superstorestaging--stagingsuperstore_staging).
