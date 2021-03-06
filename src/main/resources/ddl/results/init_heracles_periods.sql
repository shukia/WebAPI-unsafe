CREATE TABLE #temp_period (
	period_name varchar(255),
  period_order int,
  period_type varchar(50),
	period_start_date date,
	period_end_date date
);

with digits as (
	select 0 as n union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9
),
generate_dates AS
(
	SELECT
		y1.n + (10*y10.n) + (100*y100.n) + (1000*y1000.n) AS d_years,
		mths.n as d_months
	FROM
	digits y1,
	digits y10,
	(select 0 n union all select 1 union all select 9) y100,
	(select 1 n union all select 2) y1000,
	(select 1 n union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9 union all select 10 union all select 11 union all select 12) mths
	where y1.n + (10*y10.n) + (100*y100.n) + (1000*y1000.n) >= 1900 and y1.n + (10*y10.n) + (100*y100.n) + (1000*y1000.n) < 2100
),
yearly_dates as
(
	select DATEFROMPARTS(d_years, d_months,01) as generated_date
	from generate_dates
  where d_months = 1
),
monthly_dates as
(
	SELECT DATEFROMPARTS(d_years, d_months, 01) as generated_date
	from generate_dates
),
weekly_dates as (
  select dateadd(d, (7 * seq.rn), DATEFROMPARTS(1900,1,7)) as generated_date -- first sunday in 1900
	from (
		select  d1.n + (10 * d10.n) + (100 * d100.n) + (1000 * d1000.n) as rn
		from digits d1, digits d10, digits d100, digits d1000
	) seq
),
quarterly_dates as (
  SELECT DATEFROMPARTS(d_years, d_months, 1) as generated_date
	from generate_dates
	where d_months in (1,4,7,10)
)
INSERT INTO #temp_period
-- monthly dates
select CAST('Monthly' AS VARCHAR(255)) as period_name
  , 1 as period_order
  , CAST( 'mm' AS VARCHAR(50)) as period_type
  , md.generated_date as period_start_date
  , dateadd(mm,1,md.generated_date) as period_end_date
from monthly_dates md

UNION ALL
select CAST('Weekly' AS VARCHAR(255)) as period_name
  , 2 as period_order
  , CAST('ww' AS VARCHAR(50)) as period_type
  , wd.generated_date as period_start_date
  , dateadd(d, 7, wd.generated_date) as period_end_date
from weekly_dates wd
where wd.generated_date >= DATEFROMPARTS(1900,1,1) and wd.generated_date < DATEFROMPARTS(2100,1,1)

UNION ALL
select CAST('Quarterly' AS VARCHAR(255)) as period_name
  , 3 as period_order
  , CAST('qq' AS VARCHAR(50)) as period_type
  , qd.generated_date as period_start_date
  , dateadd(mm,3,qd.generated_date) as period_end_date
from quarterly_dates qd

UNION ALL
select CAST('Yearly' AS VARCHAR(255)) as period_name
  , 4 as period_order
  , CAST('yy' AS VARCHAR(50)) as period_type
  , yd.generated_date as period_start_date
  , dateadd(yy,1,yd.generated_date) as period_end_date
from yearly_dates yd

-- ADD UNION ALLs for additional period definitions
;

INSERT INTO @results_schema.heracles_periods (period_id, period_name, period_order, period_type, period_start_date, period_end_date)
select CAST(row_number() over (order by period_order, period_start_date) AS INT) as period_id
			, period_name, period_order, period_type, period_start_date, period_end_date
from #temp_period;

TRUNCATE TABLE #temp_period;
DROP TABLE #temp_period;

