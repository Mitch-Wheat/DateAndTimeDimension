set nocount on;

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'DimTimeOfDay')
BEGIN
    DROP TABLE DimTimeOfDay;
END

create table DimTimeOfDay 
( 
     TimeKey smallint not null CONSTRAINT PK_DimTimeOfDay PRIMARY KEY,    -- Note: make 'int' if grain is seconds
     HourOfDay24 tinyint not null,            -- 0-23, Military/European time 
     HourOfDay12 tinyint not null,            -- 1-12, repeating for AM/PM
     AmPm char(2) not null,                   -- AM/PM 
     MinuteOfHour tinyint not null,           -- the minute of the hour 0-59 
     HalfHour tinyint not null,               -- 1 or 2, if it is the first or second half of the hour 
     HalfHourOfDay tinyint not null,          -- 1-24, incremented at the top of each half hour 
     QuarterHour tinyint not null,            -- 1-4, for each quarter hour 
     QuarterHourOfDay tinyint not null,       -- 1-48, incremented at the top of each half hour 
     StringRepresentation24 char(5) not null, -- Military/European textual representation 
     StringRepresentation12 char(5) not null, -- 12 hour clock representation without AM/PM 
     HourIntervalString char(11) not null     -- Hour interval like 11am - 12pm
);


;with digits (i) as
( 
        select 1 as i union all select 2 as i union all select 3 union all 
        select 4 union all select 5 union all select 6 union all select 7 
        union all select 8 union all select 9 union all select 0
) 
,sequence (i) as 
( 
    SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) + (10000*D5.i) 
    FROM 
        digits AS D1 
        CROSS JOIN digits AS D2 
        CROSS JOIN digits AS D3 
        CROSS JOIN digits AS D4
        CROSS JOIN digits AS D5
) 
insert into DimTimeOfDay(TimeKey, HourOfDay24, HourOfDay12, AmPm, MinuteOfHour, HalfHour, HalfHourOfDay, QuarterHour, QuarterHourOfDay, StringRepresentation24, StringRepresentation12, HourIntervalString) 
select 
       TimeKey = i
      ,HourOfDay24   = datepart(hh, dateval)
      ,HourOfDay12   = datepart(hh, dateval) % 12 + case when datepart(hh, dateval) % 12 = 0 then 12 else 0 end 
      ,AmPm          = case when datepart(hh, dateval) between 0 and 11 then 'AM' else 'PM' end 
      ,MinuteOfHour  = datepart(mi, dateval) 
      ,HalfHour      = ((i/30) % 2) + 1		--note, values are 1 based, not 0. So the first half hour is 1, the second is 2 etc.
      ,HalfHourOfDay = (i/30) + 1 
      ,QuarterHour   = ((i/15) % 4) + 1 
      ,QuarterHourOfDay = (i/15) + 1 
      ,StringRepresentation24 = rtrim(right('0' + cast(datepart(hh, dateval) as varchar(2)),2) + ':' + right('0' + cast(datepart(mi, dateval) as varchar(2)),2) )
      ,StringRepresentation12 = rtrim(right('0' + cast(datepart(hh, dateval) % 12 + case when datepart(hh, dateval) % 12 = 0 then 12 else 0 end as varchar(2)),2) +  
                                                                  ':' + right('0' + cast(datepart(mi, dateval) as varchar(2)),2))
      ,HourIntervalString = rtrim(cast(case when ((datepart(hh, dateval)) % 12) = 0 then 12 else ((datepart(hh, dateval)) % 12) end as varchar(2)) + case when datepart(hh, dateval) between 0 and 11 then 'AM' else 'PM' end +
                            ' - ' +  cast(case when ((datepart(hh, dateval)+1) % 12) = 0 then 12 else ((datepart(hh, dateval)+1) % 12) end as varchar(2)) + case when (datepart(hh, dateval)+1) between 0 and 11 or (datepart(hh, dateval)+1)  = 24 then 'AM' else 'PM' end)
from (
      SELECT dateadd(minute, i, '20000101') AS dateVal, i 
      FROM sequence
      WHERE i BETWEEN 0 AND (60 * 24) - 1  -- number of minutes in a day = 1440
     ) as dailySeconds 
order by 
    TimeKey

---- Add an unknown time member 
--insert into DimTimeOfDay
--(TimeKey, HourOfDay24, HourOfDay12, AmPm, MinuteOfHour, HalfHour, HalfHourOfDay, 
-- QuarterHour, QuarterHourOfDay, StringRepresentation24, StringRepresentation12, HourIntervalString) 
-- select -1, 255, 255, 'NA', 255, 255, 255, 255, 255, 'NA', 'NA', 'NA'