with expected as (
    select 'SalesOrderLineKey' as col union all
    select 'CustomerKey'       as col union all
    select 'ResellerKey'       as col union all
    select 'ProductKey'        as col union all
    select 'SalesTerritoryKey' as col union all
    select 'OrderDateKey'      as col union all
    select 'Channel'           as col
),
actual as (
    select COLUMN_NAME as col
    from INFORMATION_SCHEMA.COLUMNS
    where TABLE_NAME = 'fact_sales'
)
select
    e.col as expected_col
from expected e
left join actual a
    on e.col = a.col
where a.col is null;