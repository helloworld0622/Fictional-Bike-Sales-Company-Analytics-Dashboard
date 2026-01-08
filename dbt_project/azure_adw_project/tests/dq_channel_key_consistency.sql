select
    SalesOrderLineKey,
    Channel,
    CustomerKey,
    ResellerKey
from {{ ref('fact_sales') }}
where
    (Channel = 'Online'  and (CustomerKey = -1 or CustomerKey is null or ResellerKey <> -1))
    or
    (Channel = 'Reseller' and (ResellerKey = -1 or ResellerKey is null or CustomerKey <> -1));