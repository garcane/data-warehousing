/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Schemas
  Purpose : Create the layered schemas.
  Design  : PostgreSQL supports multiple schemas per database cheaply, so we use
            them to make the warehouse LAYERS explicit - a deliberate improvement
            over the SQL Server version, which keeps everything in `dbo`.

              staging  ->  raw landing tables (source-faithful)
              dw       ->  conformed dimensions, fact, and reporting views

  Run while connected to dw_superstore:  \c dw_superstore
==============================================================================*/

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

COMMENT ON SCHEMA staging IS 'Raw landing layer - mirrors the source CSV 1:1.';
COMMENT ON SCHEMA dw      IS 'Warehouse layer - conformed dimensions, fact and reporting views.';

-- Make both layers resolvable without schema-qualifying every object.
-- (Explicit qualification is still used in the scripts for clarity.)
SET search_path TO dw, staging, public;
