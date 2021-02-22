-- Things to note:
-- 1). The TodayFlag needs to be updated once per day (timezone dependent: might need 2 flags) by a scheduled task
-- 2). If you use an unusual Fiscal year (say 5-4-4), it will need to be loaded from an external source
-- 3). Any label can have it's text changed without affecting tables referring to dimension.
-- 4). Only US federal holidays have been automatically loaded 


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'DimDate')
BEGIN
    DROP TABLE DimDate;
END
GO

declare @baseDate char(8) = '19000101';  -- also used as the 'Unknown date'
declare @startDate date   = '2000-01-01' -- Min. transaction date ?
declare @endDate date     = '2040-12-31'

declare @FiscalYearStartMonth int = 10 -- October 1st, accounting period for the US federal government; July 1st for most states

--declare @FiscalDates table
--(
--	[Period] int, 
--	[MonthNo] tinyint, 
--	[Year] smallint, 
--	[YearName] varchar(7), 
--	[Qtr] varchar(2), 
--	[Semester] varchar(2), 
--	[MonthName] varchar(9), 
--	[StartDate] date, 
--	[EndDate] date, 
--	[PeriodWeeks] tinyint,
--  [YearStartDate] date
--);

----This is the table populated from a Calendar Spreadsheet supplied by Accounts (e.g.): 
--     TODO: Automate load
--
--INSERT INTO @FiscalDates
--	([Period], [MonthNo], [Year], [YearName], [Qtr], [Semester], [MonthName], [StartDate], [EndDate], [PeriodWeeks], YearStartDate)
--VALUES
--	(201101, 1,  2011, '2010-11', 'Q1', 'S1', '1/07/2010', '2010-06-27', '2010-07-24', 4, '2010-06-27'),
--	(201102, 2,  2011, '2010-11', 'Q1', 'S1', '1/08/2010', '2010-07-25', '2010-08-28', 5, '2010-06-27'),
--	(201103, 3,  2011, '2010-11', 'Q1', 'S1', '1/09/2010', '2010-08-29', '2010-09-25', 4, '2010-06-27'),
--	(201104, 4,  2011, '2010-11', 'Q2', 'S1', '1/10/2010', '2010-09-26', '2010-10-23', 4, '2010-06-27'),
--	(201105, 5,  2011, '2010-11', 'Q2', 'S1', '1/11/2010', '2010-10-24', '2010-11-27', 5, '2010-06-27'),
--	(201106, 6,  2011, '2010-11', 'Q2', 'S1', '1/12/2010', '2010-11-28', '2010-12-25', 4, '2010-06-27'),
--	(201107, 7,  2011, '2010-11', 'Q3', 'S2', '1/01/2011', '2010-12-26', '2011-01-29', 5, '2010-06-27'),
--	(201108, 8,  2011, '2010-11', 'Q3', 'S2', '1/02/2011', '2011-01-30', '2011-02-26', 4, '2010-06-27'),
--	(201109, 9,  2011, '2010-11', 'Q3', 'S2', '1/03/2011', '2011-02-27', '2011-03-26', 4, '2010-06-27'),
--	(201110, 10, 2011, '2010-11', 'Q4', 'S2', '1/04/2011', '2011-03-27', '2011-04-23', 4, '2010-06-27'),
--	(201111, 11, 2011, '2010-11', 'Q4', 'S2', '1/05/2011', '2011-04-24', '2011-05-28', 5, '2010-06-27'),
--	(201112, 12, 2011, '2010-11', 'Q4', 'S2', '1/06/2011', '2011-05-29', '2011-06-25', 4, '2010-06-27'),

--	(201201, 1,  2012, '2011-12', 'Q1', 'S1',  '1/07/2011', '2011-06-26', '2011-07-23', 4, '2011-06-26'),
--	(201202, 2,  2012, '2011-12', 'Q1', 'S1',  '1/08/2011', '2011-07-24', '2011-08-27', 5, '2011-06-26'),
--	(201203, 3,  2012, '2011-12', 'Q1', 'S1',  '1/09/2011', '2011-08-28', '2011-09-24', 4, '2011-06-26'),
--	(201204, 4,  2012, '2011-12', 'Q2', 'S1',  '1/10/2011', '2011-09-25', '2011-10-22', 4, '2011-06-26'),
--	(201205, 5,  2012, '2011-12', 'Q2', 'S1',  '1/11/2011', '2011-10-23', '2011-11-26', 5, '2011-06-26'),
--	(201206, 6,  2012, '2011-12', 'Q2', 'S1',  '1/12/2011', '2011-11-27', '2011-12-24', 4, '2011-06-26'),
--	(201207, 7,  2012, '2011-12', 'Q3', 'S2',  '1/01/2012', '2011-12-25', '2012-01-28', 5, '2011-06-26'),
--	(201208, 8,  2012, '2011-12', 'Q3', 'S2',  '1/02/2012', '2012-01-29', '2012-02-25', 4, '2011-06-26'),
--	(201209, 9,  2012, '2011-12', 'Q3', 'S2',  '1/03/2012', '2012-02-26', '2012-03-24', 4, '2011-06-26'),
--	(201210, 10, 2012, '2011-12', 'Q4', 'S2',  '1/04/2012', '2012-03-25', '2012-04-21', 4, '2011-06-26'),
--	(201211, 11, 2012, '2011-12', 'Q4', 'S2',  '1/05/2012', '2012-04-22', '2012-05-26', 5, '2011-06-26'),
--	(201212, 12, 2012, '2011-12', 'Q4', 'S2',  '1/06/2012', '2012-05-27', '2012-06-30', 5, '2011-06-26'),

--	(201301, 1,  2013, '2012-13', 'Q1', 'S1',  '1/07/2012', '2012-07-01', '2012-07-28', 4, '2012-07-01'),
--	(201302, 2,  2013, '2012-13', 'Q1', 'S1',  '1/08/2012', '2012-07-29', '2012-08-25', 4, '2012-07-01'),
--	(201303, 3,  2013, '2012-13', 'Q1', 'S1',  '1/09/2012', '2012-08-26', '2012-09-29', 5, '2012-07-01'),
--	(201304, 4,  2013, '2012-13', 'Q2', 'S1',  '1/10/2012', '2012-09-30', '2012-10-27', 4, '2012-07-01'),
--	(201305, 5,  2013, '2012-13', 'Q2', 'S1',  '1/11/2012', '2012-10-28', '2012-11-24', 4, '2012-07-01'),
--	(201306, 6,  2013, '2012-13', 'Q2', 'S1',  '1/12/2012', '2012-11-25', '2012-12-29', 5, '2012-07-01'),
--	(201307, 7,  2013, '2012-13', 'Q3', 'S2',  '1/01/2013', '2012-12-30', '2013-01-26', 4, '2012-07-01'),
--	(201308, 8,  2013, '2012-13', 'Q3', 'S2',  '1/02/2013', '2013-01-27', '2013-02-23', 4, '2012-07-01'),
--	(201309, 9,  2013, '2012-13', 'Q3', 'S2',  '1/03/2013', '2013-02-24', '2013-03-30', 5, '2012-07-01'),
--	(201310, 10, 2013, '2012-13', 'Q4', 'S2',  '1/04/2013', '2013-03-31', '2013-04-27', 4, '2012-07-01'),
--	(201311, 11, 2013, '2012-13', 'Q4', 'S2',  '1/05/2013', '2013-04-28', '2013-05-25', 4, '2012-07-01'),
--	(201312, 12, 2013, '2012-13', 'Q4', 'S2',  '1/06/2013', '2013-05-26', '2013-06-29', 5, '2012-07-01'),

--	(201401, 1,  2014, '2013-14', 'Q1', 'S1',  '1/07/2013', '2013-06-30', '2013-07-27', 4, '2013-06-30'),
--	(201402, 2,  2014, '2013-14', 'Q1', 'S1',  '1/08/2013', '2013-07-28', '2013-08-24', 4, '2013-06-30'),
--	(201403, 3,  2014, '2013-14', 'Q1', 'S1',  '1/09/2013', '2013-08-25', '2013-09-28', 5, '2013-06-30'),
--	(201404, 4,  2014, '2013-14', 'Q2', 'S1',  '1/10/2013', '2013-09-29', '2013-10-26', 4, '2013-06-30'),
--	(201405, 5,  2014, '2013-14', 'Q2', 'S1',  '1/11/2013', '2013-10-27', '2013-11-23', 4, '2013-06-30'),
--	(201406, 6,  2014, '2013-14', 'Q2', 'S1',  '1/12/2013', '2013-11-24', '2013-12-28', 5, '2013-06-30'),
--	(201407, 7,  2014, '2013-14', 'Q3', 'S2',  '1/01/2014', '2013-12-29', '2014-01-25', 4, '2013-06-30'),
--	(201408, 8,  2014, '2013-14', 'Q3', 'S2',  '1/02/2014', '2014-01-26', '2014-02-22', 4, '2013-06-30'),
--	(201409, 9,  2014, '2013-14', 'Q3', 'S2',  '1/03/2014', '2014-02-23', '2014-03-29', 5, '2013-06-30'),
--	(201410, 10, 2014, '2013-14', 'Q4', 'S2',  '1/04/2014', '2014-03-30', '2014-04-26', 4, '2013-06-30'),
--	(201411, 11, 2014, '2013-14', 'Q4', 'S2',  '1/05/2014', '2014-04-27', '2014-05-24', 4, '2013-06-30'),
--	(201412, 12, 2014, '2013-14', 'Q4', 'S2',  '1/06/2014', '2014-05-25', '2014-06-28', 5, '2013-06-30'),

--	(201501, 1,  2015, '2014-15', 'Q1', 'S1',  '1/07/2014', '2014-06-29', '2014-07-26', 4, '2014-06-29'),
--	(201502, 2,  2015, '2014-15', 'Q1', 'S1',  '1/08/2014', '2014-07-27', '2014-08-23', 4, '2014-06-29'),
--	(201503, 3,  2015, '2014-15', 'Q1', 'S1',  '1/09/2014', '2014-08-24', '2014-09-27', 5, '2014-06-29'),
--	(201504, 4,  2015, '2014-15', 'Q2', 'S1',  '1/10/2014', '2014-09-28', '2014-10-25', 4, '2014-06-29'),
--	(201505, 5,  2015, '2014-15', 'Q2', 'S1',  '1/11/2014', '2014-10-26', '2014-11-22', 4, '2014-06-29'),
--	(201506, 6,  2015, '2014-15', 'Q2', 'S1',  '1/12/2014', '2014-11-23', '2014-12-27', 5, '2014-06-29'),
--	(201507, 7,  2015, '2014-15', 'Q3', 'S2',  '1/01/2015', '2014-12-28', '2015-01-24', 4, '2014-06-29'),
--	(201508, 8,  2015, '2014-15', 'Q3', 'S2',  '1/02/2015', '2015-01-25', '2015-02-21', 4, '2014-06-29'),
--	(201509, 9,  2015, '2014-15', 'Q3', 'S2',  '1/03/2015', '2015-02-22', '2015-03-28', 5, '2014-06-29'),
--	(201510, 10, 2015, '2014-15', 'Q4', 'S2',  '1/04/2015', '2015-03-29', '2015-04-25', 4, '2014-06-29'),
--	(201511, 11, 2015, '2014-15', 'Q4', 'S2',  '1/05/2015', '2015-04-26', '2015-05-23', 4, '2014-06-29'),
--	(201512, 12, 2015, '2014-15', 'Q4', 'S2',  '1/06/2015', '2015-05-24', '2015-06-27', 5, '2014-06-29')

--   -- * TODO: create a task to import these from Excel Spreadsheet or other source
--;

-- add NumberOfDaysInMonth

CREATE TABLE DimDate
(
	DateKey             int          NOT NULL CONSTRAINT PK_DimDate_DateKey PRIMARY KEY,
    DateValue           date         NOT NULL CONSTRAINT AKDimDate_DateValue UNIQUE,
    DateLabelUS         varchar(10)  NOT NULL,
    DateLabelUK         varchar(10)  NOT NULL,
    DateLabelISO        varchar(10)  NOT NULL,
    [DayName]           varchar(9)   NOT NULL,
    [DayShortName]      varchar(3)   NOT NULL,
    [MonthName]         varchar(9)   NOT NULL,
    [MonthShortName]    varchar(3)   NOT NULL,
    [DayOfYear]	        smallint     NOT NULL,
	[DayOfWeek]         tinyint      NOT NULL,   
    [DayOfMonth]        tinyint      NOT NULL,
    WeekInMonth		    tinyint      NOT NULL,
    ISOWeekNumber	    tinyint      NOT NULL,
	WeekendFlag		    tinyint      NOT NULL,
	TodayFlag		    tinyint      NOT NULL,
	DayIsLastOfMonth	tinyint      NOT NULL,
	IsHolidayUS         tinyint      NOT NULL,
    HolidayDescription  varchar(100) NULL,

    CalendarYear        smallint     NOT NULL,
	CalendarSemester    tinyint      NOT NULL,
    CalendarQuarter     tinyint      NOT NULL,
    CalendarMonth       tinyint      NOT NULL,
    CalendarWeek        tinyint      NOT NULL,
    CalendarYearLabel     varchar(7) NOT NULL,   
    CalendarSemesterLabel varchar(5) NOT NULL,
    CalendarQuarterLabel  varchar(5) NOT NULL,
    CalendarMonthLabel    varchar(10) NOT NULL,
    CalendarWeekLabel     varchar(9) NOT NULL,  
                                      
    -- Start of fiscal year configurable in the load process
    FiscalYear          smallint    NOT NULL,
    FiscalQuarter       tinyint     NOT NULL, 
    FiscalMonth         tinyint     NOT NULL, 
    FiscalWeek          tinyint     NOT NULL, 
    FiscalDayOfYear	    smallint    NOT NULL,
    FiscalYearLabel     varchar(6)  NOT NULL,   
    FiscalQuarterLabel  varchar(5)  NOT NULL,
    FiscalMonthLabel    varchar(10) NOT NULL,

    StartOfMonthDate    date        NOT NULL,
    EndOfMonthDate      date        NOT NULL,

    -- Used to give Relative positioning, such as the previous 10 months etc
    RelativeDayCount    int         NOT NULL,
    RelativeWeekCount   int         NOT NULL,
    RelativeMonthCount  int         NOT NULL,
	
	-- If needed, these can be filled in after table load...
    FiscalStartOfYearDate	 Date   NULL,
    FiscalEndOfYearDate		 Date   NULL,
	FiscalStartOfMonthDate	 Date   NULL,
	FiscalEndOfMonthDate	 Date   NULL,
	FiscalStartOfQuarterDate Date   NULL,
	FiscalEndOfQuarterDate	 Date   NULL,
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
    DateValue,
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

    StartOfMonthDate,
    EndOfMonthDate,
    RelativeDayCount, 
    RelativeWeekCount, 
    RelativeMonthCount
)
SELECT 
	DateKey               = YEAR(dates.d) * 10000 + MONTH(dates.d) * 100 + DAY(dates.d), 
    DateValue             = cast(dates.d as date), 
    DateLabelUS           = right('0' + cast(datepart(month, dates.d) as varchar(2)),2) + '-' +  right('0' + cast(datepart(day, dates.d) as varchar(2)),2) + '-' + cast(datepart(year, dates.d) as varchar(4)),   -- Date in MM-dd-yyyy format
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
    IsHolidayUS           = 0, -- Needs to be filled in after population. Might need multiple flags for US, AU, NZ, UK etc....??
    ISOWeekNumber         = DATEPART(ISO_WEEK, dates.d),
                          
    CalendarYear          = DATEPART(year, dates.d),                         -- 2013
    CalendarSemester      = CASE WHEN MONTH(dates.d) <= 6 THEN 1 ELSE 2 END, -- 1 - 2,                                                    
    CalendarQuarter       = (MONTH(dates.d) - 1)/3 + 1, 
    CalendarMonth         = MONTH(dates.d),                                  -- 1 - 12
    CalendarWeek          = (DATEPART(dayofyear, dates.d) + 6) / 7,          -- 1 - 53
    CalendarYearLabel     = 'CY ' + CAST(YEAR(dates.d) AS varchar(4)),
    CalendarSemesterLabel = 'CY-S' + CAST((MONTH(dates.d) - 1) / 6 + 1 AS varchar(10)),
    CalendarQuarterLabel  = 'CY-Q' + CAST((MONTH(dates.d) - 1) / 3 + 1 AS varchar(10)),
    CalendarMonthLabel    = 'CY' + CAST(YEAR(dates.d) AS varchar(4)) + '-' + LEFT(DATENAME(month, dates.d), 3),
    CalendarWeekLabel     = 'CY Week' + CAST((DATEPART(dayofyear, dates.d) + 6) / 7 AS varchar(2)),

    CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth THEN YEAR(dates.d) + 1 ELSE YEAR(dates.d) END AS FiscalYear,
    (CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth THEN MONTH(dates.d) - @FiscalYearStartMonth + 1 ELSE MONTH(dates.d) + 13 - @FiscalYearStartMonth END - 1) / 3 + 1 AS FiscalQuarter,
    CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth THEN MONTH(dates.d) - @FiscalYearStartMonth + 1 ELSE MONTH(dates.d) + 13 - @FiscalYearStartMonth END AS FiscalMonth,
    ((CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth 
        THEN DATEDIFF(day, CAST(CAST(YEAR(dates.d) AS varchar(4)) + RIGHT('0' + CAST(@FiscalYearStartMonth AS varchar(2)), 2) + '01' AS date), dates.d) + 1
        ELSE DATEDIFF(day, CAST(CAST(YEAR(dates.d) - 1 AS varchar(4)) + RIGHT('0' + CAST(@FiscalYearStartMonth AS varchar(2)), 2) + '01' AS date), dates.d) + 1
    END) + 6) / 7 AS FiscalWeek,

    CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth 
        THEN DATEDIFF(day, CAST(CAST(YEAR(dates.d) AS varchar(4)) + RIGHT('0' + CAST(@FiscalYearStartMonth AS varchar(2)), 2) + '01' AS date), dates.d) + 1
        ELSE DATEDIFF(day, CAST(CAST(YEAR(dates.d) - 1 AS varchar(4)) + RIGHT('0' + CAST(@FiscalYearStartMonth AS varchar(2)), 2) + '01' AS date), dates.d) + 1
    END AS FiscalDayOfYear,
    'FY' + CAST(CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth THEN YEAR(dates.d) + 1 ELSE YEAR(dates.d) END AS varchar(4)) AS FiscalYearLabel,
    'FY-Q' + CAST((CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth THEN MONTH(dates.d) - @FiscalYearStartMonth + 1 ELSE MONTH(dates.d) + 13 - @FiscalYearStartMonth END - 1) / 3 + 1 AS varchar(10)) AS FiscalQuarterLabel,
    'FY' + CAST(CASE WHEN MONTH(dates.d) >= @FiscalYearStartMonth THEN YEAR(dates.d) + 1 ELSE YEAR(dates.d) END AS varchar(4)) + '-' + SUBSTRING(DATENAME(month, dates.d), 1, 3) AS FiscalMonthLabel,

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
--	FiscalYear             = fd.Year,
--	FiscalSemester         = convert(tinyint, right(fd.Semester, 1)),
--    FiscalQuarter          = convert(tinyint, right(fd.Qtr, 1)),
--    FiscalMonth            = fd.MonthNo,
--    FiscalWeek             = 1 + ((datediff(day, fd.YearStartDate, dd.Date)) / 7),
--	FiscalStartOfMonthDate = fd.StartDate,
--	FiscalEndOfMonthDate   = fd.EndDate,
--    FiscalWeeksInPeriod    = fd.PeriodWeeks
--from DimDate dd
--join @FiscalDates fd ON dd.Date between fd.StartDate and fd.EndDate 

--update DimDate
--SET
--	FiscalStartOfMonthDate = convert(date, convert(char(4), [CalendarYear]) + '-' + convert(char(2), [CalendarMonth]) + '-01'),

--	FiscalEndOfMonthDate = dateadd(day, -1, DateAdd(month, 1, convert(date, convert(char(4), [CalendarYear]) + '-' + convert(char(2), [CalendarMonth]) + '-01'))),

--	FiscalStartOfYearDate = case 
--							   when [Date] <= '2011-06-25' THEN convert(date, convert(char(4), [CalendarYear]) + '-' + '01-01')
--	                           when [date] >= '2011-06-26' and [date] < '2011-07-23' THEN '2011-06-26'
--							   else '2012-07-01'
--						    end,
--	FiscalEndOfYearDate = case 
--							  when [Date] <  '2011-06-26' THEN convert(date, convert(char(4), [CalendarYear]) + '-' + '12-31')
--	                          when [date] >= '2011-06-26' and [date] <= '2012-06-30' THEN '2012-06-30'
--							  else '2013-06-29'
--						  end,
--	FiscalStartOfQuarterDate = case 
--								  when FiscalYear = 2011 then
--									case 
--                                        when FiscalMonth between 1 and 3 then    '2010-06-27'
--										 when FiscalMonth between 4 and 6 then   '2010-09-26'
--										 when FiscalMonth between 7 and 9 then   '2010-12-26'
--										 when FiscalMonth between 10 and 12 then '2011-03-27'
--									end
--								 when FiscalYear = 2012 then
--									case 
--                                         when FiscalMonth between 1 and 3 then   '2011-06-26'
--										 when FiscalMonth between 4 and 6 then   '2011-09-25'
--										 when FiscalMonth between 7 and 9 then   '2011-12-25'
--										 when FiscalMonth between 10 and 12 then '2012-03-25' 
--									end
--								 when FiscalYear = 2013 then
--									case 
--                                         when FiscalMonth between 1 and 3 then   '2012-07-01'
--										 when FiscalMonth between 4 and 6 then   '2012-09-30'
--										 when FiscalMonth between 7 and 9 then   '2012-12-30'
--										 when FiscalMonth between 10 and 12 then '2013-03-31'
--									end
--								 when FiscalYear = 2014 then
--									case 
--                                         when FiscalMonth between 1 and 3 then   '2013-06-30'
--										 when FiscalMonth between 4 and 6 then   '2013-09-29'
--										 when FiscalMonth between 7 and 9 then   '2013-12-29'
--										 when FiscalMonth between 10 and 12 then '2014-03-30'
--									end								 
--								end,
--	FiscalEndOfQuarterDate = case when FiscalYear = 2011 then
--									case when FiscalMonth between 1 and 3 then   '2010-09-25'
--										 when FiscalMonth between 4 and 6 then   '2010-11-27'
--										 when FiscalMonth between 7 and 9 then   '2011-03-26'
--										 when FiscalMonth between 10 and 12 then '2011-06-25'
--									end
--								when FiscalYear = 2012 then
--									case when FiscalMonth between 1 and 3 then   '2011-09-24'
--										 when FiscalMonth between 4 and 6 then   '2011-11-26'
--										 when FiscalMonth between 7 and 9 then   '2012-03-24'
--										 when FiscalMonth between 10 and 12 then '2012-06-30'
--									end
--								when FiscalYear = 2013 then
--									case when FiscalMonth between 1 and 3 then   '2012-09-29'
--										 when FiscalMonth between 4 and 6 then   '2012-12-29'
--										 when FiscalMonth between 7 and 9 then   '2013-03-30'
--										 when FiscalMonth between 10 and 12 then '2013-06-29'
--									end

--								when FiscalYear = 2014 then
--									case when FiscalMonth between 1 and 3 then   '2013-09-28'
--										 when FiscalMonth between 4 and 6 then   '2013-12-28'
--										 when FiscalMonth between 7 and 9 then   '2014-03-29'
--										 when FiscalMonth between 10 and 12 then '2014-06-28'
--									end
--							end

--;with cteDayNoInFiscalPeriod
--as
--(
--    select 
--		[Date], FiscalYear, FiscalMonth, 
--		row_number() over (partition by FiscalYear, FiscalMonth order by FiscalYear, FiscalMonth) as rn
--	from DimDate
--)
--update dd
--SET 
--	FiscalWeekEndDate = DateAdd(day, (35 - cte.rn)%7, cte.[Date])
--from 
--    DimDate dd
--    join cteDayNoInFiscalPeriod cte on cte.[Date] = dd.[Date]

--go

-------------------------------------------------------------------------

update DimDate
set TodayFlag = 0
where TodayFlag = 1
go

declare @today date = getdate()

update DimDate
set 
    TodayFlag = 1
where 
    DateKey = YEAR(@today) * 10000 + MONTH(@today) * 100 + DAY(@today)

-------------------------------------------------------------------------

-- update DimeDate to include US federal holidays

-- USA standard DayOfWeek : 
--   Sunday = 1 
--   Monday = 2
--   Tuesday = 3
--   Wedsnesday = 4
--   Thursday = 5
--   Friday = 6
--   Saturday = 7

-- New Years Day
UPDATE dbo.DimDate
SET HolidayDescription = 'New Year''s Day'
WHERE CalendarMonth = 1 AND DayOfMonth = 1

-- Martin Luthor King Day - Third Monday in January starting in 1983
UPDATE dbo.DimDate
SET HolidayDescription = 'Martin Luthor King Jr Day'
WHERE
    CalendarMonth = 1
    AND DayOfWeek = 2
    AND CalendarYear >= 1983
    AND WeekInMonth = 3

-- President's Day - Third Monday in February
UPDATE dbo.DimDate
SET HolidayDescription = 'President''s Day'
WHERE
    CalendarMonth = 2
    AND DayOfWeek = 2
    AND WeekInMonth = 3

-- Memorial Day - Last Monday in May
UPDATE dbo.DimDate
SET HolidayDescription = 'Memorial Day'
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
	    CalendarYear,
	    CalendarMonth
);

-- 4th of July
UPDATE dbo.DimDate
SET HolidayDescription = 'Independance Day'
WHERE CalendarMonth = 7 AND DayOfMonth = 4

-- Labor Day - First Monday in September
UPDATE dbo.DimDate
SET HolidayDescription = 'Labor Day'
FROM dbo.DimDate
WHERE 
	CalendarMonth = 9
	AND DayOfWeek = 2
    AND WeekInMonth = 1

-- Colombus Day - Second Monday in October
UPDATE dbo.DimDate
SET HolidayDescription = 'Colombus Day'
WHERE
    CalendarMonth = 10
    AND DayOfWeek = 2
    AND WeekInMonth = 2

-- Veterans Day - November 11
UPDATE dbo.DimDate
SET HolidayDescription = 'Veterans Day'
WHERE
    CalendarMonth = 11
    AND DayOfMonth = 11

-- Thanksgiving - Fourth Thursday in November
UPDATE dbo.DimDate
SET HolidayDescription = 'Thanksgiving'
WHERE CalendarMonth = 11 AND DayOfWeek = 5 AND WeekInMonth = 4

-- xmas
UPDATE dbo.DimDate
SET HolidayDescription = 'Christmas Day'
WHERE CalendarMonth = 12 AND DayOfMonth = 25

-- Election Day is statutorily set by the Federal Government as 
-- the Tuesday next after the first Monday in November, equaling the Tuesday occurring within November 2 to November 8
-- Not a public holiday in every state.
UPDATE dbo.DimDate
SET HolidayDescription = 'Election Day'
WHERE
    CalendarMonth = 11
    AND DayOfWeek = 3
    AND DayOfMonth BETWEEN 2 AND 8

----------------------------------------------

-- set flag for USA holidays ...
UPDATE dbo.DimDate
SET IsHolidayUS = 1
WHERE HolidayDescription IS NOT NULL

----------------------------------------------