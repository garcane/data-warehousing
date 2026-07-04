/*==============================================================================
  Superstore Data Warehouse  |  PostgreSQL  |  MASTER BUILD SCRIPT
  ------------------------------------------------------------------------------
  Run with psql. Because CREATE DATABASE cannot run inside another database's
  session, this is done in TWO steps:

    Step 1 - create the database (connected to the default `postgres` DB):
        psql -U postgres -f database/01_create_database.sql

    Step 2 - build everything inside it (this file):
        psql -U postgres -d dw_superstore -v ON_ERROR_STOP=1 -f run_all.sql

  Prerequisite: Superstore.csv reachable at the path in staging/02_load_staging.sql
                (default: current working directory). See /sample-data.
==============================================================================*/

\set ON_ERROR_STOP on

\echo '>>> schemas'
\i schemas/01_create_schemas.sql

\echo '>>> staging'
\i staging/01_create_staging.sql
\i staging/02_load_staging.sql

\echo '>>> warehouse DDL'
\i warehouse/01_create_dimensions.sql
\i warehouse/02_create_fact.sql

\echo '>>> warehouse load'
\i warehouse/03_load_dimensions.sql
\i warehouse/04_load_dimdate.sql
\i warehouse/05_load_fact.sql

\echo '>>> indexes'
\i indexes/01_indexes.sql

\echo '>>> views'
\i views/01_reporting_views.sql

\echo '>>> procedures'
\i procedures/sp_load_superstore_dw.sql

\echo '>>> DONE. Validate with tests/postgres/validation.sql'

/*  After the first build, reload end-to-end at any time with:
        -- reload staging first (\i staging/02_load_staging.sql), then:
        CALL dw.load_superstore_dw();
*/
