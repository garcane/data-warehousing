# Data Dictionary

Column‑level reference for the warehouse. SQL Server names are shown first;
the PostgreSQL equivalent uses `snake_case` in the `dw` / `staging` schemas
(e.g. `dimCustomer` → `dw.dim_customer`, `Customer_SK` → `customer_sk`).

Legend: **PK** primary (surrogate) key · **FK** foreign key · **NK** natural key
(business key) · **DD** degenerate dimension · **M** measure.

---

## Staging — `SuperstoreStaging` / `staging.superstore_staging`
Raw landing table, 1:1 with the source CSV. 9,994 rows.

| Column | Type (SQL Server) | Type (PostgreSQL) | Description |
|--------|-------------------|-------------------|-------------|
| Row_ID | BIGINT | BIGINT | Source line number |
| Order_ID | NVARCHAR(50) | VARCHAR(50) | Order number, e.g. `CA-2016-152156` |
| Order_Date | DATE | DATE | Date order was placed |
| Ship_Date | DATETIME2(7) | TIMESTAMP(6) | Date order was shipped |
| Ship_Mode | VARCHAR(14) | VARCHAR(14) | e.g. Standard/Second/First/Same Day |
| Customer_ID | CHAR(8) | CHAR(8) | Customer business key, e.g. `CG-12520` |
| Customer_Name | NVARCHAR(50) | VARCHAR(50) | Customer full name |
| Segment | NVARCHAR(50) | VARCHAR(50) | Consumer / Corporate / Home Office |
| Country | NVARCHAR(50) | VARCHAR(50) | Always "United States" in the sample |
| City | VARCHAR(17) | VARCHAR(17) | City |
| State | NVARCHAR(50) | VARCHAR(50) | US state |
| Postal_Code | CHAR(5) | CHAR(5) | ZIP code |
| Region | NVARCHAR(50) | VARCHAR(50) | West / East / Central / South |
| Product_ID | CHAR(15) | CHAR(15) | Product business key |
| Category | NVARCHAR(50) | VARCHAR(50) | Furniture / Office Supplies / Technology |
| Sub_Category | NVARCHAR(50) | VARCHAR(50) | e.g. Bookcases, Chairs, Phones |
| Product_Name | VARCHAR(127) | VARCHAR(127) | Product description |
| Sales | FLOAT | DOUBLE PRECISION | Line sales amount |
| Quantity | INT | INTEGER | Units sold |
| Discount | FLOAT | DOUBLE PRECISION | Discount rate 0–1 |
| Profit | FLOAT | DOUBLE PRECISION | Line profit (can be negative) |

---

## `dimDate` — calendar dimension (1,458 rows)

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| Date_SK | BIGINT | **PK** | Surrogate key |
| DateValue | DATE | NK | The calendar date |
| Day | INT | | Day of month (1–31) |
| Week | INT | | Week number (see week‑number caveat in migration guide) |
| Month | INT | | Month (1–12) |
| Quarter | INT | | Quarter (1–4) |
| Year | INT | | Year (2014–2017) |

## `dimCustomer` — customer master (794 rows)

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| Customer_SK | BIGINT | **PK** | Surrogate key |
| CustomerId | CHAR(8) | NK | Source customer id |
| CustomerName | VARCHAR(22) | | Customer name |
| CustomerSegment | VARCHAR(11) | | Segment (denormalised in — by design) |

## `dimProduct` — product master (1,894 rows)

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| Product_SK | BIGINT | **PK** | Surrogate key |
| ProductId | CHAR(15) | NK | Source product id |
| ProductName | VARCHAR(127) | NK | Product name (part of NK — ids can repeat) |
| ProductCategory | VARCHAR(15) | | Category |
| ProductSubCategory | VARCHAR(11) | | Sub‑category |

## `dimGeog` — geography (632 rows)

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| Geog_SK | BIGINT | **PK** | Surrogate key |
| Country | CHAR(13) | | Country |
| Region | VARCHAR(7) | | Region |
| State | VARCHAR(20) | | State |
| City | VARCHAR(17) | NK | City (part of NK with PostalCode) |
| PostalCode | CHAR(5) | NK | ZIP (part of NK with City) |

## `dimShipMode` — ship methods (4 rows)

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| ShipMode_SK | BIGINT | **PK** | Surrogate key |
| ShipMode | VARCHAR(14) | NK | Shipping method |

---

## `FACTOrderItem` — sales fact (9,994 rows)
**Grain: one row per order line item.**

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| Fact_SK | BIGINT | **PK** | Surrogate key |
| Row_Id | BIGINT | DD | Source line id (degenerate) |
| Order_Id | CHAR(14) | DD | Order number (degenerate) |
| Customer_SK | BIGINT | **FK**→dimCustomer | Customer |
| Product_SK | BIGINT | **FK**→dimProduct | Product |
| ShipMode_SK | BIGINT | **FK**→dimShipMode | Ship method |
| Geog_SK | BIGINT | **FK**→dimGeog | Location |
| OrderDate_SK | BIGINT | **FK**→dimDate | Order date |
| ShipDate | DATE | | Ship date (kept on fact) |
| Sales | FLOAT | M | Sales amount (additive) |
| Qty | INT | M | Quantity (additive) |
| Discount | DECIMAL(3,2) | M | Discount rate (non‑additive — average) |
| Profit | FLOAT | M | Profit (additive, may be negative) |

---

## Presentation views

| View | Grain / purpose |
|------|-----------------|
| `Cube0` | Daily sales by calendar attributes |
| `Cube1` | Sales by customer, geography, quarter |
| `Cube2` | Weekly sales by product category, segment, region |
| `Cube3` | Yearly sales by product category |
| `vCustomerSegment` | Total sales per customer segment |
| `MegaCube` | Grain‑rich "answer everything" view (date × geog × product × customer) |
