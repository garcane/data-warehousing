/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  MASTER BUILD SCRIPT (run order)
  ------------------------------------------------------------------------------
  This file documents the canonical execution order. Run each script in SSMS or
  via sqlcmd in the sequence below. (SQLCMD mode :r includes are shown as a
  convenience; enable "SQLCMD Mode" in SSMS or run with `sqlcmd -i build_all.sql`.)

  Prerequisite: place Superstore.csv at C:\Superstore.csv (see /sample-data),
                or edit the path in staging\02_load_staging.sql.
==============================================================================*/

:setvar RepoRoot "."   -- adjust to the absolute path of the sqlserver folder if needed

:r $(RepoRoot)\database\01_create_database.sql
:r $(RepoRoot)\staging\01_create_staging.sql
:r $(RepoRoot)\staging\02_load_staging.sql
:r $(RepoRoot)\warehouse\01_create_dimensions.sql
:r $(RepoRoot)\warehouse\02_create_fact.sql
:r $(RepoRoot)\warehouse\03_load_dimensions.sql
:r $(RepoRoot)\warehouse\04_load_dimdate.sql
:r $(RepoRoot)\warehouse\05_load_fact.sql
:r $(RepoRoot)\indexes\01_indexes.sql
:r $(RepoRoot)\views\01_reporting_views.sql
:r $(RepoRoot)\procedures\usp_Load_SuperstoreDW.sql

/*  After the first build you can reload end-to-end at any time with:
        EXEC dbo.usp_Load_SuperstoreDW;   -- (staging must be reloaded first)
    Then validate with the scripts under /tests/sqlserver.
*/
