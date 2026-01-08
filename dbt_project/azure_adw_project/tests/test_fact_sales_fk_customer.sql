select
    fs.CustomerKey
from {{ ref('fact_sales') }} fs
left join {{ ref('dim_customer') }} dc
    on fs.CustomerKey = dc.CustomerKey
where
    fs.CustomerKey <> -1
    and dc.CustomerKey is null;