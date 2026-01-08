{{ config(severity='error') }}

with online_customers_with_orders as (
    select distinct
        fs.CustomerKey
    from {{ ref('fact_sales') }} fs
    where
        fs.Channel = 'Online'
        and fs.CustomerKey <> -1
),

online_dim_customers as (
    select
        dc.CustomerKey,
        dc.CustomerID,
        dc.Customer
    from {{ ref('dim_customer') }} dc
    join online_customers_with_orders o
        on dc.CustomerKey = o.CustomerKey
),

missing_rfm as (
    select
        c.CustomerKey,
        c.CustomerID,
        c.Customer
    from online_dim_customers c
    left join {{ ref('dim_rfm') }} r
        on c.CustomerKey = r.CustomerKey
    where r.CustomerKey is null
)

select *
from missing_rfm;