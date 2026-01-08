select
    fs.SalesTerritoryKey
from {{ ref('fact_sales') }} fs
left join {{ ref('dim_sales_territory') }} dst
    on fs.SalesTerritoryKey = dst.SalesTerritoryKey
where dst.SalesTerritoryKey is null;