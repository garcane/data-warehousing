/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  Layer: Staging
  Purpose : Load the Superstore CSV into staging.superstore_staging.
  ------------------------------------------------------------------------------
  SQL Server BULK INSERT  ->  PostgreSQL \copy (psql client-side) / COPY (server).

  Why \copy and not COPY?
    - server-side COPY reads a path on the DATABASE SERVER and needs superuser;
    - client-side \copy (a psql meta-command) reads a path on YOUR machine and
      needs no special privilege - the portable, CI-friendly choice.

  Date handling:
    - Source dates are dd/mm/yyyy. PostgreSQL parses dates per `datestyle`, so we
      set it to DMY for this session before copying. (SQL Server used SET DATEFORMAT dmy.)

  Encoding:
    - The Superstore CSV is Windows-1252 (an Excel export) and contains bytes such
      as 0xA0 (non-breaking space) that are NOT valid UTF-8. The database is UTF-8,
      so we tell COPY the SOURCE encoding is WIN1252 and PostgreSQL transcodes it
      to UTF-8 on load. Without this you get: ERROR invalid byte sequence for UTF8.

  Edit the file path below to where Superstore.csv lives on your machine.
==============================================================================*/

SET datestyle = 'ISO, DMY';   -- interpret input dates as dd/mm/yyyy

TRUNCATE TABLE staging.superstore_staging;

-- psql meta-command: everything on ONE logical line.
-- HEADER skips the header row; product names with commas are handled by the CSV quoting.
-- ENCODING 'WIN1252' transcodes the Excel-origin source file to the UTF-8 database.
\copy staging.superstore_staging FROM 'Superstore.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252')

-- Validation: expect 9994.
SELECT count(*) AS staging_row_count FROM staging.superstore_staging;
