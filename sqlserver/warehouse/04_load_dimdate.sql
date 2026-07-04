/*==============================================================================
  Superstore Data Warehouse  |  Microsoft SQL Server
  Layer   : Warehouse (date dimension load)
  Purpose : Generate one dimDate row per calendar day across the order range.
  Range   : Derived from the staging data (MIN/MAX Order_Date), so the calendar
            always covers every fact date. Expected count: 1458 days (2014-2017).
  Note    : This set-based version replaces the original WHILE-loop approach.
            The recursive CTE is capped with OPTION (MAXRECURSION 0).
==============================================================================*/

USE DW_Superstore;
GO

TRUNCATE TABLE dbo.dimDate;
GO

DECLARE @StartDate DATE = (SELECT MIN(Order_Date) FROM dbo.SuperstoreStaging);
DECLARE @EndDate   DATE = (SELECT MAX(Order_Date) FROM dbo.SuperstoreStaging);

;WITH Calendar AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM Calendar
    WHERE DateValue < @EndDate
)
INSERT INTO dbo.dimDate (DateValue, [Day], [Week], [Month], [Quarter], [Year])
SELECT
    DateValue,
    DAY(DateValue),
    DATEPART(WEEK, DateValue),
    MONTH(DateValue),
    DATEPART(QUARTER, DateValue),
    YEAR(DateValue)
FROM Calendar
OPTION (MAXRECURSION 0);   -- lift the default 100-row recursion cap
GO

SELECT COUNT(*) AS dimDateRowCount FROM dbo.dimDate;   -- expect 1458
GO

PRINT 'dimDate loaded.';
GO
