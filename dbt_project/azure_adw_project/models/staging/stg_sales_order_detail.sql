select
    SalesOrderDetailID    as sales_order_detail_id,
    SalesOrderID          as sales_order_id,
    ProductID             as product_id,
    OrderQty              as quantity,
    UnitPrice             as unit_price,
    UnitPriceDiscount     as discount,
    LineTotal             as line_total
from {{ ref('raw_sales_order_detail') }}