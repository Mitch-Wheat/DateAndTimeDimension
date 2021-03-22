-- Things to note:
-- 1). The TodayFlag needs to be updated once per day (timezone dependent: might need 2 flags) by a scheduled task
-- 2). If you use an unusual Fiscal year (say 5-4-4), it will need to be loaded from an external source (such as an Excel spreadsheet)
-- 3). Any label can have it's text changed without affecting tables referring to dimension.


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'DimDate')
BEGIN
    DROP TABLE DimDate;
END
GO

declare @baseDate char(8) = '19000101';  -- also used as the 'Unknown date': if your dates start earlier than this pick another date (1753-01-01 maybe)
declare @startDate date   = '2000-01-01' -- Min. transaction date ?
declare @endDate date     = '2040-12-31'

declare @FYStartMonth int = 07 -- July 1st:  October 1st is accounting period for the US federal government; July 1st for most states

--declare @FiscalDates table
--(
--    [Period] int,
--    [MonthNo] tinyint,
--    [Year] smallint,
--    [YearName] varchar(7),
--    [Qtr] varchar(2),
--    [Semester] varchar(2),
--    [MonthName] varchar(9),
--    [StartDate] date,
--    [EndDate] date,
--    [PeriodWeeks] tinyint,
--  [YearStartDate] date
--);

----This is the table populated from a Calendar Spreadsheet supplied by Accounts (e.g.):
--     TODO: Automate load
--
--INSERT INTO @FiscalDates
--    ([Period], [MonthNo], [Year], [YearName], [Qtr], [Semester], [MonthName], [StartDate], [EndDate], [PeriodWeeks], YearStartDate)
--VALUES

--    (201401, 1,  2014, '2013-14', 'Q1', 'S1',  '1/07/2013', '2013-06-30', '2013-07-27', 4, '2013-06-30'),
--    (201402, 2,  2014, '2013-14', 'Q1', 'S1',  '1/08/2013', '2013-07-28', '2013-08-24', 4, '2013-06-30'),
--    (201403, 3,  2014, '2013-14', 'Q1', 'S1',  '1/09/2013', '2013-08-25', '2013-09-28', 5, '2013-06-30'),
--    (201404, 4,  2014, '2013-14', 'Q2', 'S1',  '1/10/2013', '2013-09-29', '2013-10-26', 4, '2013-06-30'),
--    (201405, 5,  2014, '2013-14', 'Q2', 'S1',  '1/11/2013', '2013-10-27', '2013-11-23', 4, '2013-06-30'),
--    (201406, 6,  2014, '2013-14', 'Q2', 'S1',  '1/12/2013', '2013-11-24', '2013-12-28', 5, '2013-06-30'),
--    (201407, 7,  2014, '2013-14', 'Q3', 'S2',  '1/01/2014', '2013-12-29', '2014-01-25', 4, '2013-06-30'),
--    (201408, 8,  2014, '2013-14', 'Q3', 'S2',  '1/02/2014', '2014-01-26', '2014-02-22', 4, '2013-06-30'),
--    (201409, 9,  2014, '2013-14', 'Q3', 'S2',  '1/03/2014', '2014-02-23', '2014-03-29', 5, '2013-06-30'),
--    (201410, 10, 2014, '2013-14', 'Q4', 'S2',  '1/04/2014', '2014-03-30', '2014-04-26', 4, '2013-06-30'),
--    (201411, 11, 2014, '2013-14', 'Q4', 'S2',  '1/05/2014', '2014-04-27', '2014-05-24', 4, '2013-06-30'),
--    (201412, 12, 2014, '2013-14', 'Q4', 'S2',  '1/06/2014', '2014-05-25', '2014-06-28', 5, '2013-06-30'),

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
    DateKey             date         NOT NULL CONSTRAINT PK_DimDate_DateKey PRIMARY KEY,
    DateLabelUS         varchar(10)  NOT NULL,
    DateLabelUK         varchar(10)  NOT NULL,
    DateLabelISO        varchar(10)  NOT NULL,
    [DayName]           varchar(9)   NOT NULL,
    [DayShortName]      varchar(3)   NOT NULL,
    [MonthName]         varchar(9)   NOT NULL,
    [MonthShortName]    varchar(3)   NOT NULL,
    [DayOfYear]         smallint     NOT NULL,
    [DayOfWeek]         tinyint      NOT NULL,  
    [DayOfMonth]        tinyint      NOT NULL,
    WeekInMonth         tinyint      NOT NULL,
    ISOWeekNumber       tinyint      NOT NULL,
    WeekendFlag         tinyint      NOT NULL,
    TodayFlag           tinyint      NOT NULL,
    DayIsLastOfMonth    tinyint      NOT NULL,
    IsHolidayUS         tinyint      NOT NULL,
    IsHolidayUK         tinyint      NOT NULL,
    IsHolidayMalta      tinyint      NOT NULL,
    IsHolidayAU         tinyint      NOT NULL,
    IsHolidayIreland    tinyint      NOT NULL,
    HolidayDescription  varchar(100) NULL,

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
    WeekendFlag,
    TodayFlag,
    DayIsLastOfMonth,
    IsHolidayUS,
    IsHolidayUK,
    IsHolidayAU,
    IsHolidayMalta,
    IsHolidayIreland,
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
    [DayOfWeek]           = DATEPART(weekday, dates.d),                      -- 1 - 7, Sunday = 1 [USA standard] (In the UK Monday =  1 and Sunday = 7)
    WeekInMonth           = ((DATEPART(day, dates.d) - 1)/7) + 1,            -- 1 - 5
    WeekendFlag           = CASE WHEN DATENAME(weekday, dates.d) in ('Saturday','Sunday') THEN 1 ELSE 0 END,  -- 1=WeekEnd, 0=WeekDay
    TodayFlag             = 0, -- This is us updated by a task that needs to runs daily...
    DayIsLastOfMonth      = CASE WHEN DATEPART(day, DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, dates.d) + 1, 0))) = DAY(dates.d) THEN 1 ELSE 0 END,
    IsHolidayUS           = 0, -- Needs to be filled in after population
    IsHolidayUK           = 0, -- Needs to be filled in after population
    IsHolidayAU           = 0, -- Needs to be filled in after population
    IsHolidayMalta        = 0, -- Needs to be filled in after population
    IsHolidayIreland      = 0, -- Needs to be filled in after population

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
    or dates.d = @baseDate) -- Dummy date placeholder for unknown dates.

order by
    DateKey


------------------------------------------------------------------------------------------    

---- Create and populate the Fiscal Dates
--update DimDate
--SET
--    FiscalYear             = fd.Year,
--    FiscalSemester         = convert(tinyint, right(fd.Semester, 1)),
--    FiscalQuarter          = convert(tinyint, right(fd.Qtr, 1)),
--    FiscalMonth            = fd.MonthNo,
--    FiscalWeek             = 1 + ((datediff(day, fd.YearStartDate, dd.Date)) / 7),
--    FiscalStartOfMonthDate = fd.StartDate,
--    FiscalEndOfMonthDate   = fd.EndDate,
--    FiscalWeeksInPeriod    = fd.PeriodWeeks
--from DimDate dd
--join @FiscalDates fd ON dd.Date between fd.StartDate and fd.EndDate

--update DimDate
--SET
--    FiscalStartOfMonthDate = convert(date, convert(char(4), [CalendarYear]) + '-' + convert(char(2), [CalendarMonth]) + '-01'),

--    FiscalEndOfMonthDate = dateadd(day, -1, DateAdd(month, 1, convert(date, convert(char(4), [CalendarYear]) + '-' + convert(char(2), [CalendarMonth]) + '-01'))),

--    FiscalStartOfYearDate = case
--                               when [Date] <= '2011-06-25' THEN convert(date, convert(char(4), [CalendarYear]) + '-' + '01-01')
--                               when [date] >= '2011-06-26' and [date] < '2011-07-23' THEN '2011-06-26'
--                               else '2012-07-01'
--                            end,
--    FiscalEndOfYearDate = case
--                              when [Date] <  '2011-06-26' THEN convert(date, convert(char(4), [CalendarYear]) + '-' + '12-31')
--                              when [date] >= '2011-06-26' and [date] <= '2012-06-30' THEN '2012-06-30'
--                              else '2013-06-29'
--                          end,
--    FiscalStartOfQuarterDate = case
--                                  when FiscalYear = 2011 then
--                                    case
--                                        when FiscalMonth between 1 and 3 then    '2010-06-27'
--                                         when FiscalMonth between 4 and 6 then   '2010-09-26'
--                                         when FiscalMonth between 7 and 9 then   '2010-12-26'
--                                         when FiscalMonth between 10 and 12 then '2011-03-27'
--                                    end
--                                 when FiscalYear = 2012 then
--                                    case
--                                         when FiscalMonth between 1 and 3 then   '2011-06-26'
--                                         when FiscalMonth between 4 and 6 then   '2011-09-25'
--                                         when FiscalMonth between 7 and 9 then   '2011-12-25'
--                                         when FiscalMonth between 10 and 12 then '2012-03-25'
--                                    end
--                                 when FiscalYear = 2013 then
--                                    case
--                                         when FiscalMonth between 1 and 3 then   '2012-07-01'
--                                         when FiscalMonth between 4 and 6 then   '2012-09-30'
--                                         when FiscalMonth between 7 and 9 then   '2012-12-30'
--                                         when FiscalMonth between 10 and 12 then '2013-03-31'
--                                    end
--                                 when FiscalYear = 2014 then
--                                    case
--                                         when FiscalMonth between 1 and 3 then   '2013-06-30'
--                                         when FiscalMonth between 4 and 6 then   '2013-09-29'
--                                         when FiscalMonth between 7 and 9 then   '2013-12-29'
--                                         when FiscalMonth between 10 and 12 then '2014-03-30'
--                                    end                                
--                                end,
--    FiscalEndOfQuarterDate = case when FiscalYear = 2011 then
--                                    case when FiscalMonth between 1 and 3 then   '2010-09-25'
--                                         when FiscalMonth between 4 and 6 then   '2010-11-27'
--                                         when FiscalMonth between 7 and 9 then   '2011-03-26'
--                                         when FiscalMonth between 10 and 12 then '2011-06-25'
--                                    end
--                                when FiscalYear = 2012 then
--                                    case when FiscalMonth between 1 and 3 then   '2011-09-24'
--                                         when FiscalMonth between 4 and 6 then   '2011-11-26'
--                                         when FiscalMonth between 7 and 9 then   '2012-03-24'
--                                         when FiscalMonth between 10 and 12 then '2012-06-30'
--                                    end
--                                when FiscalYear = 2013 then
--                                    case when FiscalMonth between 1 and 3 then   '2012-09-29'
--                                         when FiscalMonth between 4 and 6 then   '2012-12-29'
--                                         when FiscalMonth between 7 and 9 then   '2013-03-30'
--                                         when FiscalMonth between 10 and 12 then '2013-06-29'
--                                    end

--                                when FiscalYear = 2014 then
--                                    case when FiscalMonth between 1 and 3 then   '2013-09-28'
--                                         when FiscalMonth between 4 and 6 then   '2013-12-28'
--                                         when FiscalMonth between 7 and 9 then   '2014-03-29'
--                                         when FiscalMonth between 10 and 12 then '2014-06-28'
--                                    end
--                            end

--;with cteDayNoInFiscalPeriod
--as
--(
--    select
--        [Date], FiscalYear, FiscalMonth,
--        row_number() over (partition by FiscalYear, FiscalMonth order by FiscalYear, FiscalMonth) as rn
--    from DimDate
--)
--update dd
--SET
--    FiscalWeekEndDate = DateAdd(day, (35 - cte.rn)%7, cte.[Date])
--from
--    DimDate dd
--    join cteDayNoInFiscalPeriod cte on cte.[Date] = dd.[Date]

--go

-------------------------------------------------------------------------

-- Updating the TodayFlag would be a daily scheduled job...

update DimDate
set TodayFlag = 0
where TodayFlag = 1
go

declare @today date = getdate()

update DimDate
set
    TodayFlag = 1
where
    DateKey = @today

-------------------------------------------------------------------------

-- update DimDate to include US federal holidays

-- USA standard DayOfWeek:
--   Sunday = 1
--   Monday = 2
--   Tuesday = 3
--   Wedsnesday = 4
--   Thursday = 5
--   Friday = 6
--   Saturday = 7

-- New Years Day
UPDATE dbo.DimDate
SET HolidayDescription = 'New Year''s Day',
IsHolidayUS = 1
WHERE
(CalendarMonth = 1 AND DayOfMonth = 1 AND DayOfWeek BETWEEN 2 AND 6) -- Not Sat or Sun

UPDATE dbo.DimDate
SET HolidayDescription = 'New Year''s Day Holiday (in Lieu)',
IsHolidayUS = 1
WHERE
(CalendarMonth = 12 AND DayOfMonth = 31 AND DayOfWeek = 6)

UPDATE dbo.DimDate
SET HolidayDescription = 'New Year''s Day Holiday (in Lieu)',
IsHolidayUS = 1
WHERE
(CalendarMonth = 1 AND DayOfMonth = 2 AND DayOfWeek = 2)

----------

-- Martin Luthor King Day - Third Monday in January starting in 1983
UPDATE dbo.DimDate
SET HolidayDescription = 'Martin Luthor King Jr Day',
IsHolidayUS = 1
WHERE
    CalendarMonth = 1
    AND DayOfWeek = 2
    AND CalendarYear >= 1983
    AND WeekInMonth = 3

-- President's Day - Third Monday in February
UPDATE dbo.DimDate
SET HolidayDescription = 'President''s Day',
IsHolidayUS = 1
WHERE
    CalendarMonth = 2
    AND DayOfWeek = 2
    AND WeekInMonth = 3

-- Memorial Day - Last Monday in May
UPDATE dbo.DimDate
SET HolidayDescription = 'Memorial Day',
IsHolidayUS = 1
FROM dbo.DimDate
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
SET HolidayDescription = 'Independance Day',
IsHolidayUS = 1
WHERE CalendarMonth = 7 AND DayOfMonth = 4 AND DayOfWeek BETWEEN 2 AND 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Independance Day (in Lieu)',
IsHolidayUS = 1
WHERE CalendarMonth = 7 AND DayOfMonth = 3 AND DayOfWeek = 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Independance Day (in Lieu)',
IsHolidayUS = 1
WHERE CalendarMonth = 7 AND DayOfMonth = 5 AND DayOfWeek = 2

----------

-- Labor Day - First Monday in September
UPDATE dbo.DimDate
SET HolidayDescription = 'Labor Day',
IsHolidayUS = 1
FROM dbo.DimDate
WHERE
    CalendarMonth = 9
    AND DayOfWeek = 2
    AND WeekInMonth = 1

-- Colombus Day - Second Monday in October
UPDATE dbo.DimDate
SET HolidayDescription = 'Colombus Day',
IsHolidayUS = 1
WHERE
    CalendarMonth = 10
    AND DayOfWeek = 2
    AND WeekInMonth = 2

-- Veterans Day - November 11
UPDATE dbo.DimDate
SET HolidayDescription = 'Veterans Day',
IsHolidayUS = 1
WHERE
    CalendarMonth = 11 AND DayOfMonth = 11 AND DayOfWeek BETWEEN 2 AND 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Veterans Day Holiday (in Lieu)',
IsHolidayUS = 1
WHERE
    CalendarMonth = 11 AND DayOfMonth = 10 AND DayOfWeek = 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Veterans Day Holiday (in Lieu)',
IsHolidayUS = 1
WHERE
    CalendarMonth = 11 AND DayOfMonth = 12 AND DayOfWeek = 2

----------

-- Thanksgiving - Fourth Thursday in November
UPDATE dbo.DimDate
SET HolidayDescription = 'Thanksgiving',
IsHolidayUS = 1
WHERE CalendarMonth = 11 AND DayOfWeek = 5 AND WeekInMonth = 4

-- xmas
UPDATE dbo.DimDate
SET HolidayDescription = 'Christmas Day',
IsHolidayUS = 1
WHERE CalendarMonth = 12 AND DayOfMonth = 25 AND DayOfWeek BETWEEN 2 AND 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Christmas Day Holiday',
IsHolidayUS = 1
WHERE CalendarMonth = 12 AND DayOfMonth = 24 AND DayOfWeek = 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Christmas Day Holiday',
IsHolidayUS = 1
WHERE CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek = 2

----------

-- Election Day is statutorily set by the Federal Government as
-- the Tuesday next after the first Monday in November, equaling the Tuesday occurring within November 2 to November 8
-- Not a public holiday in every state.
UPDATE dbo.DimDate
SET HolidayDescription = 'Election Day',
IsHolidayUS = 1
WHERE
    CalendarMonth = 11
    AND DayOfWeek = 3
    AND DayOfMonth BETWEEN 2 AND 8
GO
----------------------------------------------

-- UK Holidays

-- update DimDate to include UK public holidays

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

create table #UKEasterDates
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
insert into #UKEasterDates(EasterFriday, EasterMonday)
select 
    EasterFriday = dateadd(day, -2, dbo.GetEasterSunday1900_2099(i)),
    EasterMonday = dateadd(day, 1, dbo.GetEasterSunday1900_2099(i))
FROM sequence
where i between 2000 AND 2099
order by i



-- USA standard DayOfWeek:
--   Sunday = 1
--   Monday = 2
--   Tuesday = 3
--   Wedsnesday = 4
--   Thursday = 5
--   Friday = 6
--   Saturday = 7

-- New Years Day
UPDATE dbo.DimDate
SET HolidayDescription = 'New Year''s Day',
IsHolidayUK = 1
WHERE
(CalendarMonth = 1 AND DayOfMonth = 1 AND DayOfWeek BETWEEN 2 AND 6) -- Not Sat or Sun

-- New year's day falls on Sat/Sun...
UPDATE dbo.DimDate
SET HolidayDescription = 'New Year''s Day Holiday (in Lieu)',
IsHolidayUK = 1
WHERE
(CalendarMonth = 1 AND DayOfMonth = 2 AND DayOfWeek = 2)
OR 
(CalendarMonth = 1 AND DayOfMonth = 3 AND DayOfWeek = 2)

----------

-- Easter Friday
UPDATE d
SET HolidayDescription = 'Good Friday',
IsHolidayUK = 1
FROM dbo.DimDate d
JOIN #UKEasterDates e ON e.EasterFriday = d.DateKey

UPDATE d
SET HolidayDescription = 'Easter Monday',
IsHolidayUK = 1
FROM dbo.DimDate d
JOIN #UKEasterDates e ON e.EasterMonday = d.DateKey

----------

-- May Day Bank Holiday - First Monday in May
UPDATE dbo.DimDate
SET HolidayDescription = 'May Day Bank Holiday',
IsHolidayUK = 1
WHERE
    CalendarMonth = 5
    AND DayOfWeek = 2
    AND WeekInMonth = 1


-- Spring Bank Holiday: Last Monday in May. Coincides with US Memorial Day
UPDATE dbo.DimDate
SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + ';Spring Bank Holiday' ELSE 'Spring Bank Holiday' END,
IsHolidayUK = 1
FROM dbo.DimDate
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


-- Summer Bank Holiday: Last Monday in August.
UPDATE dbo.DimDate
SET HolidayDescription = CASE WHEN HolidayDescription IS NOT NULL THEN HolidayDescription + ';Summer Bank Holiday' ELSE 'Summer Bank Holiday' END,
IsHolidayUK = 1
FROM dbo.DimDate
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

---------

-- xmas Day

UPDATE dbo.DimDate
SET HolidayDescription = 'Christmas Day',
IsHolidayUK = 1
WHERE CalendarMonth = 12 AND DayOfMonth = 25 AND DayOfWeek BETWEEN 2 AND 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Christmas Day Holiday',
IsHolidayUK = 1
WHERE 
(CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek = 2)
OR
(CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 2)

-- Boxing Day

UPDATE dbo.DimDate
SET HolidayDescription = 'Boxing Day',
IsHolidayUK = 1
WHERE CalendarMonth = 12 AND DayOfMonth = 26 AND DayOfWeek BETWEEN 2 AND 6

UPDATE dbo.DimDate
SET HolidayDescription = 'Boxing Day Holiday',
IsHolidayUK = 1
WHERE 
(CalendarMonth = 12 AND DayOfMonth = 27 AND DayOfWeek = 2)
OR
(CalendarMonth = 12 AND DayOfMonth = 28 AND DayOfWeek = 3)


----------------------------------------------

-- Australian Holidays (NSW based)
-- See https://en.wikipedia.org/wiki/Public_holidays_in_Australia


----------------------------------------------

-- Malta Holidays

----------------------------------------------

-- Irish Holidays

----------------------------------------------


----------------------------------------------