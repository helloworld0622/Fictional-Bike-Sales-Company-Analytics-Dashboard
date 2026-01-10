{{ config(materialized='view') }}


with last_year as (
    select
        CustomerKey,
        max(year(orderdate)) as LastYear
    from {{ ref('fact_sales') }}
    where CustomerKey <> -1
    group by CustomerKey
),
base as (
    select
        fs.CustomerKey,
        max(fs.orderdate) as LastOrderDate,
        count(distinct fs.OrderDateKey) as F_Value,
        sum(
            case
                when year(fs.orderdate) = ly.LastYear then fs.[Sales Amount]
                else 0
            end
        ) as M_Value
    from {{ ref('fact_sales') }} fs
    join last_year ly
        on fs.CustomerKey = ly.CustomerKey
    where fs.CustomerKey <> -1
    group by fs.CustomerKey, ly.LastYear
),
recency as (
    select
        b.CustomerKey,
        cast(b.LastOrderDate as date) as LastOrderDate,
        datediff(day, b.LastOrderDate,
            (select max(orderdate) from {{ ref('fact_sales') }})
        ) as R_Value,
        b.F_Value,
        b.M_Value,
        case when b.M_Value > 0
            then log(b.M_Value + 1.0)
            else 0.0
        end as M_Value_Log
    from base b
),
rf_quantiles as (
    select distinct
        PERCENTILE_CONT(0.2) WITHIN GROUP (order by cast(R_Value as float)) over () as r_p20,
        PERCENTILE_CONT(0.4) WITHIN GROUP (order by cast(R_Value as float)) over () as r_p40,
        PERCENTILE_CONT(0.6) WITHIN GROUP (order by cast(R_Value as float)) over () as r_p60,
        PERCENTILE_CONT(0.8) WITHIN GROUP (order by cast(R_Value as float)) over () as r_p80,
        PERCENTILE_CONT(0.2) WITHIN GROUP (order by cast(F_Value as float)) over () as f_p20,
        PERCENTILE_CONT(0.4) WITHIN GROUP (order by cast(F_Value as float)) over () as f_p40,
        PERCENTILE_CONT(0.6) WITHIN GROUP (order by cast(F_Value as float)) over () as f_p60,
        PERCENTILE_CONT(0.8) WITHIN GROUP (order by cast(F_Value as float)) over () as f_p80
    from recency
),
m_quantiles as (
    select distinct
        PERCENTILE_CONT(0.2) WITHIN GROUP (order by cast(M_Value_Log as float)) over () as m_p20,
        PERCENTILE_CONT(0.4) WITHIN GROUP (order by cast(M_Value_Log as float)) over () as m_p40,
        PERCENTILE_CONT(0.6) WITHIN GROUP (order by cast(M_Value_Log as float)) over () as m_p60,
        PERCENTILE_CONT(0.8) WITHIN GROUP (order by cast(M_Value_Log as float)) over () as m_p80
    from recency
    where M_Value > 0
),
bounds as (
    select top 1
        rf.*, m.m_p20, m.m_p40, m.m_p60, m.m_p80
    from rf_quantiles rf
    cross join m_quantiles m
),
scored as (
    select
        r.CustomerKey,
        r.R_Value,
        r.F_Value,
        r.M_Value,
        r.LastOrderDate,
        case
            when r.F_Value <= b.f_p20 then 1
            when r.F_Value <= b.f_p40 then 2
            when r.F_Value <= b.f_p60 then 3
            when r.F_Value <= b.f_p80 then 4
            else 5
        end as F_Score,
        case
            when r.M_Value = 0 then 1
            when r.M_Value_Log <= b.m_p20 then 1
            when r.M_Value_Log <= b.m_p40 then 2
            when r.M_Value_Log <= b.m_p60 then 3
            when r.M_Value_Log <= b.m_p80 then 4
            else 5
        end as M_Score,
        case
            when r.R_Value <= b.r_p20 then 5
            when r.R_Value <= b.r_p40 then 4
            when r.R_Value <= b.r_p60 then 3
            when r.R_Value <= b.r_p80 then 2
            else 1
        end as R_Score

    from recency r
    cross join bounds b
)
select
    s.CustomerKey,
    s.CustomerKey as [Customer ID],
    s.R_Value as [R Value],
    s.F_Value as [F Value],
    s.M_Value as [M Value],
    cast(s.R_Score as varchar(1)) as [R Score],
    cast(s.F_Score as varchar(1)) as [F Score],
    cast(s.M_Score as varchar(1)) as [M Score],
    concat(
        cast(s.R_Score as varchar(1)),
        cast(s.F_Score as varchar(1)),
        cast(s.M_Score as varchar(1))
    ) as RFM
from scored s;