{{ config(severity='warn') }}

select
    SalesOrderLineKey,
    Channel,
    orderdate,
    [Sales Amount],
    [Total Product Cost],
    [Gross Profit],
    [Gross_Profit_Ratio]
from {{ ref('fact_sales') }}
where [Gross Profit] < 0;