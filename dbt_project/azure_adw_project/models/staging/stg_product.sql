{{ config(materialized='view') }}

select
    ProductID            as product_id,
    Name                 as product_name,
    ProductNumber        as product_number,
    Color                as color,
    ListPrice            as list_price,
    StandardCost         as standard_cost,
    ProductSubcategoryID as product_subcategory_id,
    ProductModelID       as product_model_id
from Production.Product;