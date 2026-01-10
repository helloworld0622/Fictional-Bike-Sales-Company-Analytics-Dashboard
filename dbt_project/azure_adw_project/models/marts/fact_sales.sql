{{ config(materialized='view') }}

with detail as (
    select
        sales_order_detail_id,
        sales_order_id,
        product_id,
        quantity,
        unit_price,
        discount,
        line_total
    from {{ ref('stg_sales_order_detail') }}
),
header as (
    select
        sales_order_id,
        order_date,
        due_date,
        ship_date,
        customer_id,
        salesperson_id,
        territory_id,
        online_flag
    from {{ ref('stg_sales_order_header') }}
),
cust as (
    select
        customer_id,
        person_id,
        store_id
    from {{ ref('stg_customer') }}
),
prod as (
    select
        product_id,
        standard_cost
    from {{ ref('stg_product') }}
),
base as (
    select
        case
            when h.online_flag = 1
                then c.customer_id     -- Internet → CustomerID
            else
                -1                     -- Reseller → Not Applicable
        end as CustomerKey,
        case
            when h.online_flag = 0
                then c.store_id         -- Reseller → StoreID
            else
                -1                     -- Internet → Not Applicable
        end as ResellerKey,
        d.product_id as ProductKey,
        h.territory_id as SalesTerritoryKey,
        -- Date keys are generated in YYYYMMDD format
        convert(int, convert(char(8), h.order_date,112)) as OrderDateKey,
        convert(int, convert(char(8), h.due_date,112))   as DueDateKey,
        convert(int, convert(char(8), h.ship_date,112))  as ShipDateKey,
        -- Order Line Key (unique)
        concat(
            h.sales_order_id,
            right('000' + cast(d.sales_order_detail_id as varchar(3)),3)
        ) as SalesOrderLineKey,
        -- Monetary and quantity measures required for sales performance and profitability analysis
        d.quantity as [Order Quantity],
        d.unit_price as [Unit Price],
        d.line_total as [Extended Amount],
        d.discount as [Unit Price Discount Pct],
        p.standard_cost as [Product Standard Cost],
        d.quantity * p.standard_cost as [Total Product Cost],
        d.line_total as [Sales Amount],
        cast(h.order_date as date) as orderdate,
        cast(h.ship_date as date) as shipdate,
        datediff(day, h.order_date, h.ship_date) as DaysDifference,
        case 
            when h.online_flag = 1 then 'Online'
            else 'Reseller'
        end as Channel,
        d.line_total - (d.quantity * p.standard_cost) as [Gross Profit],
        case
            when d.line_total = 0 then null
            else (d.line_total - (d.quantity * p.standard_cost)) / d.line_total
        end as [Gross_Profit_Ratio]
    from detail d
    join header h
      on d.sales_order_id = h.sales_order_id
    left join cust c
      on h.customer_id = c.customer_id
    left join prod p
      on d.product_id = p.product_id
),
distinct_purchase as (
    select
        CustomerKey,
        count(distinct OrderDateKey) as Distinct_Purchase_Count2
    from base
    where CustomerKey <> -1
    group by CustomerKey
)

select
    b.*,
    dp.Distinct_Purchase_Count2
from base b
left join distinct_purchase dp
    on b.CustomerKey = dp.CustomerKey;