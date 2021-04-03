/*
MIT License

Copyright (c) 2021 Mitch Wheat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

-- Things to note:
-- 1). The TodayFlag needs to be updated once per day (timezone dependent: might need 2 flags) by a scheduled task
-- 2). If you use an unusual Fiscal year (say 5-4-4), it will need to be loaded from an external source (such as an Excel spreadsheet)

-------------------------------------------------------------------------

-- Create a daily scheduled job to set the TodayFlag
CREATE OR ALTER PROCEDURE SetDimDateTodayFlag
AS
BEGIN
    SET NOCOUNT ON;

    update DimDate
    set TodayFlag = 0
    where TodayFlag = 1;

    declare @today date = getdate();

    update DimDate
    set
        TodayFlag = 1
    where
        DateKey = @today;
END
GO

-------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE CreateDateDimension
(
    @startDate date   = '2000-01-01',
    @endDate date     = '2040-12-31',
    @FYStartMonth int = 7, -- FY start July 1st. (October 1st is accounting period for the US federal government; July 1st for most states)
    @unknownDate date = '1901-01-01'
)
AS
BEGIN

SET NOCOUNT ON;

If @startDate >= @endDate 
BEGIN
    RAISERROR ('Start date must be less than end date.', 0, 1) WITH NOWAIT
    RETURN
END

If @unknownDate >= @startdate
BEGIN
    RAISERROR ('Unknown date must be less than start date.', 0, 1) WITH NOWAIT
    RETURN
END

If @startDate < '1901-01-01' 
BEGIN
    RAISERROR ('Easter dates will be incorrect prior to 1901', 0, 1) WITH NOWAIT
END

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'DimDate')
BEGIN
    DROP TABLE dbo.DimDate;
END

declare @baseDate date;  -- if your dates start earlier than this pick another date (1753-01-01 maybe)

SET @baseDate = @unknownDate

--declare @FiscalDates table
--(
--  [Period] int,
--  [MonthNo] tinyint,
--  [Year] smallint,
--  [YearName] varchar(7),
--  [Qtr] varchar(2),
--  [Semester] varchar(2),
--  [MonthName] varchar(9),
--  [StartDate] date,
--  [EndDate] date,
--  [PeriodWeeks] tinyint,
--  [YearStartDate] date
--);

----This is the table populated from a Calendar Spreadsheet supplied by Accounts (e.g.):
--     TODO: Automate load
--
--INSERT INTO @FiscalDates
--    ([Period], [MonthNo], [Year], [YearName], [Qtr], [Semester], [MonthName], [StartDate], [EndDate], [PeriodWeeks], YearStartDate)
--VALUES
--    (201501, 1,  2015, '2014-15', 'Q1', 'S1',  '1/07/2014', '2014-06-29', '2014-07-26', 4, '2014-06-29'),
--    (201502, 2,  2015, '2014-15', 'Q1', 'S1',  '1/08/2014', '2014-07-27', '2014-08-23', 4, '2014-06-29'),
--    (201503, 3,  2015, '2014-15', 'Q1', 'S1',  '1/09/2014', '2014-08-24', '2014-09-27', 5, '2014-06-29'),
--    (201504, 4,  2015, '2014-15', 'Q2', 'S1',  '1/10/2014', '2014-09-28', '2014-10-25', 4, '2014-06-29'),
--    (201505, 5,  2015, '2014-15', 'Q2', 'S1',  '1/11/2014', '2014-10-26', '2014-11-22', 4, '2014-06-29'),
--    (201506, 6,  2015, '2014-15', 'Q2', 'S1',  '1/12/2014', '2014-11-23', '2014-12-27', 5, '2014-06-29'),
--    (201507, 7,  2015, '2014-15', 'Q3', 'S2',  '1/01/2015', '2014-12-28', '2015-01-24', 4, '2014-06-29'),
--    (201508, 8,  2015, '2014-15', 'Q3', 'S2',  '1/02/2015', '2015-01-25', '2015-02-21', 4, '2014-06-29'),
--    (201509, 9,  2015, '2014-15', 'Q3', 'S2',  '1/03/2015', '2015-02-22', '2015-03-28', 5, '2014-06-29'),
--    (201510, 10, 2015, '2014-15', 'Q4', 'S2',  '1/04/2015', '2015-03-29', '2015-04-25', 4, '2014-06-29'),
--    (201511, 11, 2015, '2014-15', 'Q4', 'S2',  '1/05/2015', '2015-04-26', '2015-05-23', 4, '2014-06-29'),
--    (201512, 12, 2015, '2014-15', 'Q4', 'S2',  '1/06/2015', '2015-05-24', '2015-06-27', 5, '2014-06-29')
--;

------------------------------------------------------------------------------------------

CREATE TABLE DimDate
(
    DateKey               date         NOT NULL CONSTRAINT PK_DimDate_DateKey PRIMARY KEY,
    DateLabelUS           varchar(10)  NOT NULL,
    DateLabelUK           varchar(10)  NOT NULL,
    DateLabelISO          varchar(10)  NOT NULL,
    [DayName]             varchar(9)   NOT NULL,
    [DayShortName]        varchar(3)   NOT NULL,
    [MonthName]           varchar(9)   NOT NULL,
    [MonthShortName]      varchar(3)   NOT NULL,
    [DayOfYear]           smallint     NOT NULL,
    [DayOfWeek]           tinyint      NOT NULL,  
    [DayOfMonth]          tinyint      NOT NULL,
    WeekInMonth           tinyint      NOT NULL,
    ISOWeekNumber         tinyint      NOT NULL,
    IsWeekDay             tinyint      NOT NULL,
    TodayFlag             tinyint      NOT NULL,
    DayIsLastOfMonth      tinyint      NOT NULL,
    IsHolidayUS           tinyint      NOT NULL,
    IsHolidayUK           tinyint      NOT NULL,
    IsHolidayMalta        tinyint      NOT NULL,
    IsHolidayAU           tinyint      NOT NULL,
    IsHolidayIreland      tinyint      NOT NULL,
    IsHolidayCanada       tinyint      NOT NULL,
    IsHolidayPhilippines  tinyint      NOT NULL,
    HolidayDescription    varchar(200) NULL,

    CalendarYear          smallint    NOT NULL,
    CalendarSemester      tinyint     NOT NULL,
    CalendarQuarter       tinyint     NOT NULL,
    CalendarMonth         tinyint     NOT NULL,
    CalendarWeek          tinyint     NOT NULL,
    CalendarYearLabel     varchar(7)  NOT NULL,  
    CalendarSemesterLabel varchar(5)  NOT NULL,
    CalendarQuarterLabel  varchar(5)  NOT NULL,
    CalendarMonthLabel    varchar(10) NOT NULL,
    CalendarWeekLabel     varchar(9)  NOT NULL,  
                                     
    -- Start of fiscal year configurable in the load process
    FiscalYear          smallint    NOT NULL,
    FiscalQuarter       tinyint     NOT NULL,
    FiscalMonth         tinyint     NOT NULL,
    FiscalWeek          tinyint     NOT NULL,
    FiscalDayOfYear     smallint    NOT NULL,
    FiscalYearLabel     varchar(6)  NOT NULL,  
    FiscalQuarterLabel  varchar(5)  NOT NULL,
    FiscalMonthLabel    varchar(10) NOT NULL,

    DaysInMonth         tinyint     NOT NULL,
    StartOfMonthDate    date        NOT NULL,
    EndOfMonthDate      date        NOT NULL,

    -- Used to give Relative positioning, such as the previous 10 months etc
    RelativeDayCount    int         NOT NULL,
    RelativeWeekCount   int         NOT NULL,
    RelativeMonthCount  int         NOT NULL,
   
    -- If needed, these can be filled in after table load...
    FiscalStartOfYearDate    Date   NULL,
    FiscalEndOfYearDate      Date   NULL,
    FiscalStartOfMonthDate   Date   NULL,
    FiscalEndOfMonthDate     Date   NULL,
    FiscalStartOfQuarterDate Date   NULL,
    FiscalEndOfQuarterDate   Date   NULL,
    FiscalWeekEndDate        Date   NULL,
    FiscalWeeksInPeriod      int    NULL
);

------------------------------------------------------------------------------------------

;WITH digits(i) AS
(
    SELECT 1 AS I UNION ALL SELECT 2 AS I UNION ALL SELECT 3 UNION ALL
    SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 0
)
,sequence(i) AS
(
    SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) + (10000*D5.i) + + (100000*D6.i)
    FROM digits AS D1
    CROSS JOIN digits AS D2
    CROSS JOIN digits AS D3
    CROSS JOIN digits AS D4
    CROSS JOIN digits AS D5
    CROSS JOIN digits AS D6
)
,dates(d) AS
(
    SELECT DATEADD(day, i, '17530101') AS d FROM sequence
)
INSERT DimDate
(
    DateKey,
    DateLabelUS,
    DateLabelUK,
    DateLabelISO,
    [DayName],
    DayShortName,
    [MonthName],
    MonthShortName,
    [DayOfYear],
    [DayOfMonth],
    [DayOfWeek],
    WeekInMonth,
    IsWeekDay,
    TodayFlag,
    DayIsLastOfMonth,
    IsHolidayUS,
    IsHolidayUK,
    IsHolidayAU,
    IsHolidayMalta,
    IsHolidayIreland,
    IsHolidayCanada,
    IsHolidayPhilippines,
    ISOWeekNumber,

    CalendarYear,
    CalendarSemester,
    CalendarQuarter,
    CalendarMonth,
    CalendarWeek,  -- This is US WeekNumberOfYear
    CalendarYearLabel,  
    CalendarSemesterLabel,
    CalendarQuarterLabel,
    CalendarMonthLabel,
    CalendarWeekLabel,  
   
    FiscalYear,
    FiscalQuarter,
    FiscalMonth,
    FiscalWeek,
    FiscalDayOfYear,
    FiscalYearLabel,
    FiscalQuarterLabel,
    FiscalMonthLabel,

    DaysInMonth,
    StartOfMonthDate,
    EndOfMonthDate,
    RelativeDayCount,
    RelativeWeekCount,
    RelativeMonthCount
)
SELECT
    DateKey               = cast(dates.d as date), --Other option is encoded integer: YEAR(dates.d) * 10000 + MONTH(dates.d) * 100 + DAY(dates.d),
    DateLabelUS           = right('0' + cast(datepart(month, dates.d) as varchar(2)),2) + '-' + right('0' + cast(datepart(day, dates.d) as varchar(2)),2) + '-' + cast(datepart(year, dates.d) as varchar(4)),    -- Date in MM-dd-yyyy format
    DateLabelUK           = right('0' + cast(datepart(day, dates.d) as varchar(2)),2) + '-' + right('0' + cast(datepart(month, dates.d) as varchar(2)),2) + '-' + cast(datepart(year, dates.d) as varchar(4)),    -- Date in dd-MM-yyyy format
    DateLabelISO          = cast(datepart(year, dates.d) as varchar(4))  + '-' + right('0' + cast(datepart(month, dates.d) as varchar(2)),2) + '-' +  right('0' + cast(datepart(day, dates.d) as varchar(2)),2),  -- Date in yyyy-MM-dd format
    [DayName]             = DATENAME(weekday, dates.d),                      -- Monday
    [DayShortName]        = LEFT(DATENAME(dw, dates.d), 3),                  -- Mon
    [MonthName]           = DATENAME(month, dates.d),                        -- April
    [MonthShortName]      = LEFT(DATENAME(month, dates.d), 3),               -- Apr
    [DayOfYear]           = DATEPART(dayofyear, dates.d),                    -- 1 - 366
    [DayOfMonth]          = DATEPART(day, dates.d),                          -- 1 - 31
    [DayOfWeek]           = DATEPART(weekday, dates.d),                      -- 1 - 7, Using Sunday = 1 [USA standard] (In the UK Monday =  1 and Sunday = 7)
    WeekInMonth           = ((DATEPART(day, dates.d) - 1)/7) + 1,            -- 1 - 5
    IsWeekDay             = CASE WHEN DATENAME(weekday, dates.d) in ('Saturday','Sunday') THEN 0 ELSE 1 END,  -- 0 = WeekEnd, 1 = WeekDay
    TodayFlag             = 0, -- This is us updated by a task that needs to runs daily...
    DayIsLastOfMonth      = CASE WHEN DATEPART(day, DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, dates.d) + 1, 0))) = DAY(dates.d) THEN 1 ELSE 0 END,
    IsHolidayUS           = 0, -- Needs to be filled in after population
    IsHolidayUK           = 0, -- Needs to be filled in after population
    IsHolidayAU           = 0, -- Needs to be filled in after population
    IsHolidayMalta        = 0, -- Needs to be filled in after population
    IsHolidayIreland      = 0, -- Needs to be filled in after population
    IsHolidayCanada       = 0, -- Needs to be filled in after population
    IsHolidayPhilippines  = 0, -- Needs to be filled in after population

    ISOWeekNumber         = DATEPART(ISO_WEEK, dates.d),
                         
    CalendarYear          = DATEPART(year, dates.d),                         -- e.g. 2013
    CalendarSemester      = CASE WHEN MONTH(dates.d) <= 6 THEN 1 ELSE 2 END, -- 1 - 2,                                                    
    CalendarQuarter       = (MONTH(dates.d) - 1)/3 + 1,                      -- 1 - 4
    CalendarMonth         = MONTH(dates.d),                                  -- 1 - 12
    CalendarWeek          = (DATEPART(dayofyear, dates.d) + 6) / 7,          -- 1 - 53
    CalendarYearLabel     = 'CY ' + CAST(YEAR(dates.d) AS varchar(4)),
    CalendarSemesterLabel = 'CY-S' + CAST((MONTH(dates.d) - 1) / 6 + 1 AS varchar(10)),
    CalendarQuarterLabel  = 'CY-Q' + CAST((MONTH(dates.d) - 1) / 3 + 1 AS varchar(10)),
    CalendarMonthLabel    = 'CY' + CAST(YEAR(dates.d) AS varchar(4)) + '-' + LEFT(DATENAME(month, dates.d), 3),
    CalendarWeekLabel     = 'CY Week' + CAST((DATEPART(dayofyear, dates.d) + 6) / 7 AS varchar(2)),

    CASE WHEN MONTH(dates.d) >= @FYStartMonth THEN YEAR(dates.d) + 1 ELSE YEAR(dates.d) END AS FiscalYear,
    (CASE WHEN MONTH(dates.d) >= @FYStartMonth THEN MONTH(dates.d) - @FYStartMonth + 1 ELSE MONTH(dates.d) + 13 - @FYStartMonth END - 1) / 3 + 1 AS FiscalQuarter,
    CASE WHEN MONTH(dates.d) >= @FYStartMonth THEN MONTH(dates.d) - @FYStartMonth + 1 ELSE MONTH(dates.d) + 13 - @FYStartMonth END AS FiscalMonth,
    ((CASE WHEN MONTH(dates.d) >= @FYStartMonth
        THEN DATEDIFF(day, DATEFROMPARTS(YEAR(dates.d), @FYStartMonth, 1), dates.d) + 1
        ELSE DATEDIFF(day, DATEFROMPARTS(YEAR(dates.d) - 1, @FYStartMonth, 1), dates.d) + 1
    END) + 6) / 7 AS FiscalWeek,

    CASE WHEN MONTH(dates.d) >= @FYStartMonth
        THEN DATEDIFF(day, DATEFROMPARTS(YEAR(dates.d), @FYStartMonth, 1), dates.d) + 1
        ELSE DATEDIFF(day, DATEFROMPARTS(YEAR(dates.d) - 1, @FYStartMonth, 1), dates.d) + 1
    END AS FiscalDayOfYear,

    'FY' + CAST(CASE WHEN MONTH(dates.d) >= @FYStartMonth THEN YEAR(dates.d) + 1 ELSE YEAR(dates.d) END AS varchar(4)) AS FiscalYearLabel,
    'FY-Q' + CAST((CASE WHEN MONTH(dates.d) >= @FYStartMonth THEN MONTH(dates.d) - @FYStartMonth + 1 ELSE MONTH(dates.d) + 13 - @FYStartMonth END - 1) / 3 + 1 AS varchar(10)) AS FiscalQuarterLabel,
    'FY' + CAST(CASE WHEN MONTH(dates.d) >= @FYStartMonth THEN YEAR(dates.d) + 1 ELSE YEAR(dates.d) END AS varchar(4)) + '-' + SUBSTRING(DATENAME(month, dates.d), 1, 3) AS FiscalMonthLabel,

    DaysInMonth = datediff(day, cast(DATEFROMPARTS(YEAR(dates.d), MONTH(dates.d), 1) as date), cast(EOMONTH(dates.d) as date)) + 1,
    cast(DATEFROMPARTS(YEAR(dates.d), MONTH(dates.d), 1) as date) AS StartOfMonthDate,
    cast(EOMONTH(dates.d) as date) AS EndOfMonthDate,

    -- These values can be based from any date, as long as they provide contiguous values on year and month boundries
    DATEDIFF(day, @baseDate, dates.d) AS RelativeDayCount,
    DATEDIFF(week, @baseDate, dates.d) AS RelativeWeekCount,
    DATEDIFF(month, @baseDate, dates.d) AS RelativeMonthCount
from    
    dates
where  
    ((dates.d between @startDate and @endDate)
    or dates.d = @baseDate) -- Placeholder for unknown dates.
order by
    DateKey;

EXEC SetAllHolidays;

EXEC SetDimDateTodayFlag;

END

GO

------------------------------------------------------------------------------------------    

-- Set Region based holidays

CREATE OR ALTER PROCEDURE SetAllHolidays
AS
BEGIN
    SET NOCOUNT ON;

    EXEC SetCommonHolidayDays;

    EXEC SetUSHolidays;
    EXEC SetUKHolidays;
    EXEC SetIrelandHolidays;
    EXEC SetMaltaHolidays;
    EXEC SetCanadaHolidays
    EXEC SetPhilippinesHolidays;

END
GO

------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE SetUSHolidays
AS
BEGIN
    SET NOCOUNT ON;

    -- US federal holidays

    -- USA standard DayOfWeek:
    --   Sunday = 1
    --   Monday = 2
    --   Tuesday = 3
    --   Wedsnesday = 4
    --   Thursday = 5
    --   Friday = 6
    --   Saturday = 7

    -- New Years Day falling Mon to Fri is Common (above)

    UPDATE d
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'New Year''s Day Holiday', 'US'),  
        IsHolidayUS = 1
    FROM 
        dbo.DimDate d
    WHERE
        (CalendarMonth = 12 AND DayOfMonth = 31 AND DayOfWeek = 6)
        OR
        (CalendarMonth = 1 AND DayOfMonth = 2 AND DayOfWeek = 2)

    ----------

    -- Martin Luthor King Day - Third Monday in January starting in 1983
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Martin Luthor King Jr Day', 'US'),
        IsHolidayUS = 1
    WHERE
        CalendarMonth = 1 AND DayOfWeek = 2 AND CalendarYear >= 1983 AND WeekInMonth = 3

    -- President's Day - Third Monday in February
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'President''s Day (US)',
        IsHolidayUS = 1
    WHERE
        CalendarMonth = 2 AND DayOfWeek = 2 AND WeekInMonth = 3

    -- Memorial Day - Last Monday in May
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Memorial Day (US)',
        IsHolidayUS = 1
    WHERE DateKey IN
    (
        SELECT
            MAX(DateKey)
        FROM dbo.DimDate
        WHERE
            CalendarMonth = 5
            AND DayOfWeek = 2
        GROUP BY
            CalendarYear
    );

    -- 4th of July
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Independance Day (US)',
        IsHolidayUS = 1
    WHERE 
        CalendarMonth = 7 AND DayOfMonth = 4 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Independance Day Holiday (US)',
    IsHolidayUS = 1
    WHERE 
        (CalendarMonth = 7 AND DayOfMonth = 3 AND DayOfWeek = 6)
        OR
        (CalendarMonth = 7 AND DayOfMonth = 5 AND DayOfWeek = 2)

    ----------

    -- Labor Day - First Monday in September
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Labor Day (US)',
        IsHolidayUS = 1
    FROM dbo.DimDate
    WHERE
        CalendarMonth = 9 AND DayOfWeek = 2 AND WeekInMonth = 1

    -- Colombus Day - Second Monday in October
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Colombus Day (US)',
        IsHolidayUS = 1
    WHERE
        CalendarMonth = 10 AND DayOfWeek = 2 AND WeekInMonth = 2

    -- Election Day is statutorily set by the Federal Government as
    -- the Tuesday next after the first Monday in November, equaling the Tuesday occurring within November 2 to November 8
    -- Not a public holiday in every state...
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Election Day (US)',
        IsHolidayUS = 1
    WHERE
        CalendarMonth = 11 AND DayOfWeek = 3 AND DayOfMonth BETWEEN 2 AND 8

    ----------

    -- Veterans Day - November 11
    UPDATE dbo.DimDate
    SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Veterans Day (US)',
    IsHolidayUS = 1
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 11 AND DayOfWeek BETWEEN 2 AND 6)

    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Veterans Day Holiday (US)',
        IsHolidayUS = 1
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 10 AND DayOfWeek = 6)
        OR
        (CalendarMonth = 11 AND DayOfMonth = 12 AND DayOfWeek = 2)

    -- Thanksgiving - Fourth Thursday in November
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Thanksgiving (US)',
        IsHolidayUS = 1
    WHERE CalendarMonth = 11 AND DayOfWeek = 5 AND WeekInMonth = 4

    -- xmas
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Christmas Day Holiday', 'US'),
        IsHolidayUS = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 24 AND DayOfWeek = 6)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek = 2)

END
GO

------------------------------------------------------------------------------------------
-- update DimDate to include UK public holidays
CREATE OR ALTER PROCEDURE SetUKHolidays
AS
BEGIN
    SET NOCOUNT ON;

    -- UK Holidays

    -- USA standard DayOfWeek:
    --   Sunday     = 1
    --   Monday     = 2
    --   Tuesday    = 3
    --   Wedsnesday = 4
    --   Thursday   = 5
    --   Friday     = 6
    --   Saturday   = 7

    -- New Years Day falling Mon to Fri is Common (above)

    -- New year's day falls on Sat/Sun...
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'New Year''s Day Holiday', 'UK'),
        IsHolidayUK = 1
    WHERE
        (CalendarMonth = 1 AND DayOfMonth = 2 AND DayOfWeek = 2)
        OR 
        (CalendarMonth = 1 AND DayOfMonth = 3 AND DayOfWeek = 2)

    ----------

    -- May Day Bank Holiday - First Monday in May
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'May Day (UK)'   ,
        IsHolidayUK = 1
    WHERE
        (CalendarMonth = 5 AND DayOfWeek = 2 AND WeekInMonth = 1)

    -- Spring Bank Holiday: Last Monday in May. Coincides with US Memorial Day
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Spring Bank Holiday (UK)',
        IsHolidayUK = 1
    WHERE DateKey IN
    (
        SELECT
            MAX(DateKey)
        FROM dbo.DimDate
        WHERE
            CalendarMonth = 5 AND DayOfWeek = 2
        GROUP BY
            CalendarYear
    );

    -- Summer Bank Holiday: Last Monday in August.
    UPDATE dbo.DimDate
        SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Summer Bank Holiday (UK)',
        IsHolidayUK = 1
    WHERE DateKey IN
    (
        SELECT
            MAX(DateKey)
        FROM dbo.DimDate
        WHERE
            CalendarMonth = 8 AND DayOfWeek = 2
        GROUP BY
            CalendarYear
    );

    -- xmas Day (falling on a Sat or Sun)
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Christmas Day Holiday', 'UK'),
        IsHolidayUK = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek = 2)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 2)

    -- Boxing Day
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Boxing Day', 'UK'),
        IsHolidayUK = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek BETWEEN 3 AND 6)

    -- falling on a Sat or Sun
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Boxing Day Holiday', 'UK'),
        IsHolidayUK = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 3)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 3)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 2)

END
GO

------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE SetMaltaHolidays
AS
BEGIN
    SET NOCOUNT ON;

    -- Malta Holidays

    -- Since 2006, public holidays that fall on a weekend do not get a holiday day in lieu.
    -- (Malta has most holidays of all the countries in the European Union).

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Feast of Saint Paul''s Shipwreck (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 2 AND DayOfMonth = 10 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Feast of Saint Joseph (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 3 AND DayOfMonth = 19 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Freedom Day (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 3 AND DayOfMonth = 31 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Worker''s Day (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 5 AND DayOfMonth = 1 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Sette Giugno (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 6 AND DayOfMonth = 7 AND DayOfWeek BETWEEN 2 AND 6
    
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Feast of St. Peter and St. Paul (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 6 AND DayOfMonth = 29 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Feast of the Assumption (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 8 AND DayOfMonth = 15 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Victory Day (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 9 AND DayOfMonth = 8 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Independence Day (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 9 AND DayOfMonth = 21 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Feast of the Immaculate Conception (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 12 AND DayOfMonth = 8 AND DayOfWeek BETWEEN 2 AND 6

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Republic Day (MLT)',
        IsHolidayMalta = 1
    WHERE
        CalendarMonth = 12 AND DayOfMonth = 13 AND DayOfWeek BETWEEN 2 AND 6

END
GO

------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE SetIrelandHolidays
AS
BEGIN
    SET NOCOUNT ON;

    -- Irish Holidays

    -- Saint Patrick's Day, March 17th
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Saint Patrick''s Day (IRL)',
        IsHolidayIreland = 1
    WHERE
        (CalendarMonth = 3 AND DayOfMonth = 17 AND DayOfWeek BETWEEN 2 AND 6)
        OR
        (CalendarMonth = 3 AND DayOfMonth = 18 AND DayOfWeek = 2)
        OR
        (CalendarMonth = 3 AND DayOfMonth = 19 AND DayOfWeek = 2)

    -- May Day: The first Monday in May.
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'May Day', 'IRL'),
        IsHolidayIreland = 1
    WHERE
        CalendarMonth = 5
        AND DayOfWeek = 2
        AND WeekInMonth = 1

    -- June Holiday: The first Monday in June.
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'June Holiday (IRL)',
        IsHolidayIreland = 1
    WHERE
        CalendarMonth = 6
        AND DayOfWeek = 2
        AND WeekInMonth = 1

    -- August Holiday: The first Monday in August.
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'August Holiday (IRL)',
        IsHolidayIreland = 1
    WHERE
        CalendarMonth = 8
        AND DayOfWeek = 2
        AND WeekInMonth = 1

    -- October Holiday:The last Monday in October.
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'October Holiday (IRL)',
        IsHolidayIreland = 1
    WHERE DateKey IN
    (
        SELECT
            MAX(DateKey)
        FROM dbo.DimDate
        WHERE
            CalendarMonth = 10
            AND DayOfWeek = 2
        GROUP BY
            CalendarYear
    );

    -- xmas day falling on a Sat or Sun
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Christmas Day Holiday', 'IRL'),
        IsHolidayIreland = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek = 2)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 2)

    -- St. Stephen's Day 26th December

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'St. Stephen''s Day (IRL)',
        IsHolidayIreland = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek BETWEEN 3 AND 6)

    -- ...falling on a Sat or Sun
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'St. Stephen''s Day Holiday (IRL)',
        IsHolidayIreland = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 3)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 3)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 2)

END
GO

--------------------------------------------------------------------------------------------

--CREATE OR ALTER PROCEDURE SetAUHolidays
--AS
--BEGIN
--    SET NOCOUNT ON;



--END
--GO

------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE SetCommonHolidayDays
AS
BEGIN
    SET NOCOUNT ON;

    -- Common Holidays

    -- xmas day where it falls on a Mon to Fri
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Christmas Day (US, UK, MLT, IRE, AU, CAN, PHL)',
        IsHolidayUS = 1,
        IsHolidayUK = 1,
        IsHolidayMalta = 1,
        IsHolidayIreland = 1,
        IsHolidayAU = 1,
        IsHolidayCanada = 1,
        IsHolidayPhilippines = 1
    WHERE 
        CalendarMonth = 12 AND DayOfMonth = 25 AND DayOfWeek BETWEEN 2 AND 6

    -- New Year's day where it falls on a Mon to Fri
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'New Year''s Day (US, UK, MLT, IRE, AU, CAN, PHL)',
        IsHolidayUS = 1,
        IsHolidayUK = 1,
        IsHolidayMalta = 1,
        IsHolidayIreland = 1,
        IsHolidayAU = 1,
        IsHolidayCanada = 1,
        IsHolidayPhilippines = 1
    WHERE
        CalendarMonth = 1 AND DayOfMonth = 1 AND DayOfWeek BETWEEN 2 AND 6

    -- Easter
    if object_id('tempdb..#EasterDates') is not null
        drop table #EasterDates;

    create table #EasterDates
    (
        EasterFriday date not null,
        EasterMonday date not null
    );

    ;WITH digits(i) AS
    (
        SELECT 1 AS I UNION ALL SELECT 2 AS I UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 0
    )
    ,sequence(i) AS
    (
        SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) 
        FROM digits AS D1
        CROSS JOIN digits AS D2
        CROSS JOIN digits AS D3
        CROSS JOIN digits AS D4
    )
    insert into #EasterDates(EasterFriday, EasterMonday)
    select 
        EasterFriday = dateadd(day, -2, dbo.GetEasterSunday1900_2099(i)),
        EasterMonday = dateadd(day, 1, dbo.GetEasterSunday1900_2099(i))
    FROM sequence
    where i between 1901 AND 2099
    order by i;

    -- Easter Friday
    UPDATE d
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Good Friday (UK, AU, MLT, CAN, PHL)',
        IsHolidayUK = 1,
        IsHolidayAU = 1,
        IsHolidayMalta = 1,
        IsHolidayCanada = 1,
        IsHolidayPhilippines = 1
    FROM dbo.DimDate d
    JOIN #EasterDates e ON e.EasterFriday = d.DateKey;

    -- Easter Monday
    UPDATE d
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Easter Monday (UK, AU, IRL)',
        IsHolidayUK = 1,
        IsHolidayAU = 1,
        IsHolidayIreland = 1
    FROM dbo.DimDate d
    JOIN #EasterDates e ON e.EasterMonday = d.DateKey;

    -- Maundy Thursday
    UPDATE d
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Maundy Thursday (PHL)',
        IsHolidayPhilippines = 1
    FROM dbo.DimDate d
    JOIN #EasterDates e ON dateadd(day, -1, e.EasterFriday) = d.DateKey;

    -- Black Saturday
    UPDATE d
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Black Saturday (PHL)',
        IsHolidayPhilippines = 1
    FROM dbo.DimDate d
    JOIN #EasterDates e ON dateadd(day, +1, e.EasterFriday) = d.DateKey;

    drop table #EasterDates;

    ---------------------------------------------------------------------

    -- Chinese New Year
    if object_id('tempdb..#ChineseNewYearDates') is not null
        drop table #ChineseNewYearDates;

    create table #ChineseNewYearDates
    (
        [Date] date not null
    );

    INSERT INTO #ChineseNewYearDates([Date])
    VALUES
    ('1971-01-27'), ('1972-02-15'), ('1973-02-03'), ('1974-01-23'), ('1975-02-11'), ('1976-01-31'), ('1977-02-18'), ('1978-02-07'), ('1979-01-28'), ('1980-02-16'), 
    ('1981-02-05'), ('1982-01-25'), ('1983-02-13'), ('1984-02-02'), ('1985-02-20'), ('1986-02-09'), ('1987-01-29'), ('1988-02-17'), ('1989-02-06'), ('1990-01-27'), 
    ('1991-02-15'), ('1992-02-04'), ('1993-01-23'), ('1994-02-10'), ('1995-01-31'), ('1996-02-19'), ('1997-02-07'), ('1998-01-28'), ('1999-02-16'), ('2000-02-05'), 
    ('2001-01-24'), ('2002-02-12'), ('2003-02-01'), ('2004-01-22'), ('2005-02-09'), ('2006-01-29'), ('2007-02-18'), ('2008-02-07'), ('2009-01-26'), ('2010-02-14'), 
    ('2011-02-03'), ('2012-01-23'), ('2013-02-10'), ('2014-01-31'), ('2015-02-19'), ('2016-02-08'), ('2017-01-28'), ('2018-02-16'), ('2019-02-05'), ('2020-01-25'), 
    ('2021-02-12'), ('2022-02-01'), ('2023-01-22'), ('2024-02-10'), ('2025-01-29'), ('2026-02-17'), ('2027-02-06'), ('2028-01-26'), ('2029-02-13'), ('2030-02-03'), 
    ('2031-01-23'), ('2032-02-11'), ('2033-01-31'), ('2034-02-19'), ('2035-02-08'), ('2036-01-28'), ('2037-02-15'), ('2038-02-04'), ('2039-01-24'), ('2040-02-12'), 
    ('2041-02-01'), ('2042-01-22'), ('2043-02-10'), ('2044-01-30'), ('2045-02-17'), ('2046-02-06'), ('2047-01-26'), ('2048-02-14'), ('2049-02-02'), ('2050-01-23'), 
    ('2051-02-11'), ('2052-02-01'), ('2053-02-19'), ('2054-02-08'), ('2055-01-28'), ('2056-02-15'), ('2057-02-04'), ('2058-01-24'), ('2059-02-12'), ('2060-02-02'), 
    ('2061-01-21'), ('2062-02-09'), ('2063-01-29'), ('2064-02-17'), ('2065-02-05'), ('2066-01-26'), ('2067-02-14'), ('2068-02-03'), ('2069-01-23'), ('2070-02-11'), 
    ('2071-01-31'), ('2072-02-19'), ('2073-02-07'), ('2074-01-27'), ('2075-02-15'), ('2076-02-05'), ('2077-01-24'), ('2078-02-12'), ('2079-02-02'), ('2080-01-22'), 
    ('2081-02-09'), ('2082-01-29'), ('2083-02-17'), ('2084-02-06'), ('2085-01-26'), ('2086-02-14'), ('2087-02-03'), ('2088-01-24'), ('2089-02-10'), ('2090-01-30'), 
    ('2091-02-18'), ('2092-02-07'), ('2093-01-27'), ('2094-02-15'), ('2095-02-05'), ('2096-01-25'), ('2097-02-12'), ('2098-02-01'), ('2099-01-21')

    UPDATE d
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Chinese Lunar New Year', 'PHL'),
        IsHolidayPhilippines = 1
    FROM dbo.DimDate d
    JOIN #ChineseNewYearDates e ON e.Date = d.DateKey;

    DROP TABLE #ChineseNewYearDates;

END
GO

-------------------------------------------------------------------------

-- For Years 1900 - 2099
-- https://stackoverflow.com/questions/2192533/function-to-return-date-of-easter-for-the-given-year
--
CREATE OR ALTER FUNCTION dbo.GetEasterSunday1900_2099(@year INT)
RETURNS Date 
AS 
BEGIN 
    DECLARE     
        @EpactCalc INT,  
        @PaschalDaysCalc INT, 
        @NumOfDaysToSunday INT, 
        @EasterMonth INT, 
        @EasterDay INT 

    SET @EpactCalc = (24 + 19 * (@year % 19)) % 30 
    SET @PaschalDaysCalc = @EpactCalc - (@EpactCalc / 28) 
    SET @NumOfDaysToSunday = @PaschalDaysCalc - ((@year + @year / 4 + @PaschalDaysCalc - 13) % 7) 
    SET @EasterMonth = 3 + (@NumOfDaysToSunday + 40) / 44 
    SET @EasterDay = @NumOfDaysToSunday + 28 - (31 * (@EasterMonth / 4)) 

    RETURN CONVERT(Date, RTRIM(@year) + RIGHT('0' + RTRIM(@EasterMonth), 2) + RIGHT('0' + RTRIM(@EasterDay), 2)) 
END 
GO

-------------------------------------------------------------------------

-- Australian Holidays (State based)
-- See https://en.wikipedia.org/wiki/Public_holidays_in_Australia

-- TODO ...

-------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE SetCanadaHolidays
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'New Year''s Day Holiday', 'CAN'),
        IsHolidayCanada = 1
    WHERE
        (CalendarMonth = 1 AND DayOfMonth = 2 AND DayOfWeek = 2)
        OR 
        (CalendarMonth = 1 AND DayOfMonth = 3 AND DayOfWeek = 2)

    -- Family Day - Third Monday in February
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Family Day', 'CAN'),
        IsHolidayCanada = 1
    WHERE
        (CalendarMonth = 2 AND DayOfWeek = 2 AND WeekInMonth = 3)

    -- Canada Day
    UPDATE d
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Canada Day',
        IsHolidayCanada = 1
    FROM 
        dbo.DimDate d
    WHERE
        (CalendarMonth = 7 AND DayOfMonth = 1 AND DayOfWeek BETWEEN 2 AND 6)

    UPDATE d
    SET 
        HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + '; ' ELSE '' END + 'Canada Day Holiday',
        IsHolidayCanada = 1
    FROM 
        dbo.DimDate d
    WHERE
        (CalendarMonth = 7 AND DayOfWeek = 2) AND (DayOfMonth IN (2,3))

    -----------

    -- Labor Day - First Monday in September
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Labour Day', 'CAN'),
        IsHolidayCanada = 1
    WHERE
        CalendarMonth = 9 AND DayOfWeek = 2 AND WeekInMonth = 1

    -- Victoria Day: Monday before May 25
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Victoria Day', 'CAN'),
        IsHolidayCanada = 1
    WHERE DateKey IN
    (
        SELECT
            MAX(DateKey)
        FROM dbo.DimDate
        WHERE
            CalendarMonth = 5 AND DayOfWeek = 2 AND DayOfMonth < 25
        GROUP BY
            CalendarYear
    );

    -- Civic Holiday (not Quebec)
    UPDATE dbo.DimDate
    SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Civic Holiday', 'CAN'), 
        IsHolidayCanada = 1
    WHERE
        CalendarMonth = 8 AND DayOfWeek = 2 AND WeekInMonth = 1

    -- Thanksgiving - 2nd Monday in October
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Thanksgiving', 'CAN'),
        IsHolidayCanada = 1
    WHERE 
        CalendarMonth = 10 AND DayOfWeek = 2 AND WeekInMonth = 2

    -- Remembrance Day - 11th November
    UPDATE d
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Remembrance Day', 'CAN'),
        IsHolidayCanada = 1
    FROM 
        dbo.DimDate d
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 11 AND DayOfWeek BETWEEN 2 AND 6)

    UPDATE d
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Remembrance Day Holiday', 'CAN'),
        IsHolidayCanada = 1
    FROM 
        dbo.DimDate d
    WHERE
        (CalendarMonth = 11 AND DayOfWeek = 2) AND (DayOfMonth IN (12, 13))

    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Christmas Day Holiday', 'CAN'),
        IsHolidayCanada = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfWeek = 2) AND (DayOfMonth IN (26, 27))

    -- Boxing Day
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Boxing Day', 'CAN'),
        IsHolidayCanada = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek BETWEEN 3 AND 6)

    -- falling on a Sat or Sun
    UPDATE dbo.DimDate
    SET 
        HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Boxing Day Holiday', 'CAN'),
        IsHolidayCanada = 1
    WHERE 
        (CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 3)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 3)
        OR
        (CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 2)

END
GO

-------------------------------------------------------------------------

-- https://en.wikipedia.org/wiki/Public_holidays_in_the_Philippines
-- The act specified that holidays falling on a Wednesday will be observed on the Monday of that week, 
-- that holidays falling on a Sunday will be observed on the Monday that follows, 
-- and provided that regular holidays and special days may be modified by order or proclamation

-- It appears that regular (public) holidays that fall on a weekend don't get holiday days in lieu (?) TODO: double-check this....

CREATE OR ALTER PROCEDURE SetPhilippinesHolidays
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'New Year''s Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        CalendarMonth = 1 AND DayOfMonth = 1 AND DayOfWeek IN (1, 7);

    -- People Power Anniversary: 25th February
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'People Power Anniversary', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 2 AND DayOfMonth = 25);

    -- Day of Valor: 9th April
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Day of Valor', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 4 AND DayOfMonth = 9);

    -- Labor Day: 1st May
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Labor Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 5 AND DayOfMonth = 1);

    -- Independence Day: 12th June
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Independence Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 6 AND DayOfMonth = 12);

    -- Ninoy Aquino Day: 21st Auguest
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Ninoy Aquino Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 8 AND DayOfMonth = 21);

    -- National Heroes' Day: Last Monday in August
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'National Heroes'' Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE DateKey IN
    (
        SELECT
            MAX(DateKey)
        FROM dbo.DimDate
        WHERE
            CalendarMonth = 8
            AND DayOfWeek = 2
        GROUP BY
            CalendarYear
    );

    -- All Saints' Day: 1st November
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'All Saints'' Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 1);

    -- All Souls' Day: 2nd November
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'All Souls'' Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 2);

    -- Bonifacio Day: 30th November
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Bonifacio Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 30);

    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Feast of the Immaculate Conception', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        CalendarMonth = 12 AND DayOfMonth = 8;

    -- Rizal Day: 30th December
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Rizal Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 12 AND DayOfMonth = 30);

    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Christmas Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        CalendarMonth = 12 AND DayOfMonth = 25 AND DayOfWeek IN (1, 7);

    -- New Year's Eve: 31st December
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'New Year''s Eve', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        CalendarMonth = 12 AND DayOfMonth = 31;

    -- Special moveable dates: Ramadan 2021
    -- 13 May	Thursday	Eidul-Fitar
    -- 20 Jul	Tuesday	    Eid al-Adha (Feast of the Sacrifice)
    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Eidul-Fitar', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        CalendarYear = 2021 AND CalendarMonth = 5 AND DayOfMonth = 13;

    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'Eid al-Adha (Feast of the Sacrifice)', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        CalendarYear = 2021 AND CalendarMonth = 7 AND DayOfMonth = 20;


    -- Special hoiday changes by presidential proclamation....

    -- New Year's Eve: 31st December 2021 is a working-holiday 
    UPDATE dbo.DimDate
        SET IsHolidayPhilippines = 0
    WHERE
        CalendarYear >= 2021 AND CalendarMonth = 12 AND DayOfMonth = 31;

    UPDATE dbo.DimDate
        SET HolidayDescription = dbo.AddCountryToHolidayDescription(HolidayDescription, 'All Souls'' Day', 'PHL'),
        IsHolidayPhilippines = 1
    WHERE
        (CalendarMonth = 11 AND DayOfMonth = 2);

END
GO

-------------------------------------------------------------------------

CREATE OR ALTER FUNCTION dbo.AddCountryToHolidayDescription
(
    @desc varchar(4000),
    @string_to_find varchar(100),
    @country_to_add varchar(3)
)
RETURNS varchar(8000)
AS
BEGIN
    declare @pos int, @parens int
    declare @result varchar(8000)

    IF @desc IS NULL
        RETURN @string_to_find + ' (' + @country_to_add + ')';

    SET @pos = CHARINDEX(@string_to_find, @desc);

    IF @pos > 0
    BEGIN
        SET @parens = CHARINDEX(')', @desc, @pos)

        -- if found, add country to existing list of countries
        IF @parens > 0
        BEGIN
            SET @result = substring(@desc, 1, @parens - 1) + ', ' + @country_to_add + substring(@desc, @parens , LEN(@desc) - @parens + 1);
        END
    END
    
    IF @result IS NULL
    BEGIN
        SET @result = @desc + '; ' + @string_to_find + ' (' + @country_to_add + ')';
    END

    RETURN @result
END
GO

--select dbo.AddCountryToHolidayDescription('Christmas Day Holiday (UK)', 'Christmas Day Holiday', 'XXX')
--select dbo.AddCountryToHolidayDescription('Blah Blah Day (UK)', 'Christmas Day Holiday', 'XXX')
--select dbo.AddCountryToHolidayDescription(NULL, 'Christmas Day Holiday', 'XXX')

GO


-------------------------------------------------------------------------

-- Create a date dimension table

EXEC CreateDateDimension @startDate = '2000-01-01', @endDate = '2040-12-31', @FYStartMonth = 7
GO


-------------------------------------------------------------------------
