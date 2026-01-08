select
    fs.ProductKey
from {{ ref('fact_sales') }} fs
left join {{ ref('dim_product') }} dp
    on fs.ProductKey = dp.ProductKey
where dp.ProductKey is null;