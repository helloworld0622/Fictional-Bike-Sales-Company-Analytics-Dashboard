select
    SalesOrderID       as sales_order_id,
    OrderDate          as order_date,
    DueDate            as due_date,
    ShipDate           as ship_date,
    CustomerID         as customer_id,
    SalesPersonID      as salesperson_id,
    TerritoryID        as territory_id,
    TotalDue           as total_due,
    TaxAmt             as tax_amount,
    Freight            as freight_amount,
    OnlineOrderFlag    as online_flag
from {{ ref('raw_sales_order_header') }}