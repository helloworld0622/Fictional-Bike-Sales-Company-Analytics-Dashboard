{{ config(materialized='view') }}

with p as (
    select
        product_id,
        product_name,
        product_number,
        color,
        list_price,
        standard_cost,
        product_subcategory_id,
        product_model_id
    from {{ ref('stg_product') }}
),
psc as (
    -- Resolve product category and subcategory hierarchy
    select
        ProductSubcategoryID,
        ProductCategoryID,
        Name as Subcategory
    from Production.ProductSubcategory
),
pc as (
    select
        ProductCategoryID,
        Name as Category
    from Production.ProductCategory
),
pm as (
    select
        ProductModelID,
        Name as Model
    from Production.ProductModel
)
select
    p.product_id as ProductKey,
    p.product_name as Product,
    p.product_number as SKU,
    p.color as Color,
    p.list_price as [List Price],
    p.standard_cost as [Standard Cost],
    pc.Category as Category,
    psc.Subcategory as Subcategory,
    pm.Model as Model
from p
left join psc
    on p.product_subcategory_id = psc.ProductSubcategoryID
left join pc
    on psc.ProductCategoryID = pc.ProductCategoryID
left join pm
    on p.product_model_id = pm.ProductModelID;