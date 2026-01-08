{{ config(materialized='view') }}

with p as (
    -- 基础商品信息，全部来自 staging
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
    -- 子类 → 大类
    select
        ProductSubcategoryID,
        ProductCategoryID,
        Name as Subcategory
    from Production.ProductSubcategory
),

pc as (
    -- 大类名称
    select
        ProductCategoryID,
        Name as Category
    from Production.ProductCategory
),

pm as (
    -- 型号名称
    select
        ProductModelID,
        Name as Model
    from Production.ProductModel
)

select
    -- 维度主键
    p.product_id      as ProductKey,

    -- 商品基础信息
    p.product_name    as Product,
    p.product_number  as SKU,
    p.color           as Color,

    -- 价格与成本
    p.list_price      as [List Price],
    p.standard_cost   as [Standard Cost],

    -- 分类信息
    pc.Category       as Category,
    psc.Subcategory   as Subcategory,
    pm.Model          as Model

from p
left join psc
    on p.product_subcategory_id = psc.ProductSubcategoryID
left join pc
    on psc.ProductCategoryID = pc.ProductCategoryID
left join pm
    on p.product_model_id = pm.ProductModelID;