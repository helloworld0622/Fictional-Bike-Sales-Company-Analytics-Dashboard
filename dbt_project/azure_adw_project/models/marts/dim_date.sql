{{ config(materialized='view') }}

with bounds as (
    select
        cast(min(order_date) as date) as min_date,
        cast(max(ship_date)  as date) as max_date
    from {{ ref('stg_sales_order_header') }}
),
numbers as (
    select row_number() over(order by (select 1)) - 1 as n
    from sys.all_objects
),
calendar as (
    select
        dateadd(day, n, b.min_date) as [Date]
    from bounds b
    join numbers n
      on n.n <= datediff(day, b.min_date, b.max_date)
)
select
    convert(int, convert(char(8), [Date], 112)) as DateKey,
    cast([Date] as date) as [Date],
    cast([Date] as date) as [Full Date],  
    year([Date]) as [Year],
    month([Date]) as [Month],
    -- MonthKey: 2019-07 → 201907
    (year([Date]) * 100 + month([Date])) as MonthKey,
    datename(month, [Date]) as [Month Name],
    datepart(quarter, [Date]) as [Fiscal Quarter],
    case
        when month([Date]) >= 7
            then concat('FY', year([Date]) + 1)
        else concat('FY', year([Date]))
    end as [Fiscal Year]
from calendar;