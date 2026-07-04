# Business Problem

## Context

The business (a retail "Superstore" operating across the United States) captures
every sales transaction in an operational, day‑to‑day system (an **OLTP**
database). That system is optimised for **writing** orders quickly and safely —
it is normalised (3NF), lightly indexed, and tuned for insert/update.

## The problem

Managers and analysts need to answer questions like:

- What were **total sales and quantities** last month / quarter / year?
- Which **product categories** and **customer segments** drive the most revenue?
- How do sales break down by **region, state, and city**?
- Which are the **top‑performing months**?
- How is **profit** and **discount** trending over time?

Running these analytical queries directly against the OLTP system is a bad idea:

1. **Performance conflict.** Analytical queries scan large date ranges and
   aggregate. The indexes that make this fast would *slow down* the write
   workload the OLTP system exists to serve. (More indexes = faster reads but
   slower writes — see [`/archive/Day 1/notes`](../archive/Day%201/notes).)
2. **Shape mismatch.** A normalised OLTP schema forces analysts to write many
   joins for every report. Business users can't self‑serve.
3. **History.** OLTP systems often purge or archive completed transactions;
   analysis needs the full history retained.

## The solution

Build a dedicated **analytical data warehouse (OLAP)** — a separate,
read‑optimised database that:

- stores historical sales data in a **denormalised star schema** that mirrors
  how the business *thinks* (facts = events, dimensions = the "by what?");
- is **heavily indexed** for fast aggregation;
- is populated on a schedule by an **ETL/ELT pipeline** from source files;
- exposes **presentation‑layer views** ("cubes") that BI tools such as Power BI
  consume directly, so managers get self‑service reporting.

## Success criteria

| Goal | How it is met |
|------|---------------|
| Fast slice‑and‑dice reporting | Star schema + indexes + pre‑aggregated cube views |
| Single version of the truth | Conformed dimensions (one `dim_customer`, one `dim_date`, …) |
| Trustworthy numbers | Data‑quality tests reconcile fact totals back to source |
| Repeatable loads | Idempotent, transactional load procedure |
| Portability | Same model delivered on **SQL Server** *and* **PostgreSQL** |

## Scope & assumptions

- Source data is the well‑known **Superstore** sample (9,994 order lines,
  2014–2017, US only). It stands in for a real sales feed.
- The warehouse is **rebuilt from source** for each load (full refresh). The
  dataset is small; full refresh keeps the project easy to reason about. The
  design notes ([`etl-process.md`](etl-process.md)) describe how this would
  evolve to **incremental** loads and **slowly changing dimensions** at scale.
- All data is synthetic/sample — no production data, credentials, or PII.
