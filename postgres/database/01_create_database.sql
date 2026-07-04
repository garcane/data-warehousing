/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Database
  Purpose : Create the dw_superstore database.
  Run as  : A role with CREATEDB (e.g. postgres). Connect to an ADMIN database
            (e.g. `postgres`) when running this file, because you cannot drop a
            database you are connected to.
  Usage   : psql -U postgres -f database/01_create_database.sql
  ------------------------------------------------------------------------------
  Dialect note vs SQL Server:
    - PostgreSQL has no `USE db` / `GO` batch separator. Each statement ends in
      `;`. You connect to a database with `\c` (psql) instead of `USE`.
    - CREATE DATABASE cannot run inside a transaction block or a DO block, so it
      lives in its own file that you run while connected elsewhere.
==============================================================================*/

-- Terminate other sessions so the drop can proceed (safe for a demo/CI reset).
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'dw_superstore' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS dw_superstore;
CREATE DATABASE dw_superstore
    ENCODING = 'UTF8'
    TEMPLATE = template0;

-- Next: connect to it and run schemas/01_create_schemas.sql
--   \c dw_superstore
