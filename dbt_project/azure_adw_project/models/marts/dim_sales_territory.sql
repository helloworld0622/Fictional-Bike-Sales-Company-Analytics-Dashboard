{{ config(materialized='view') }}

with t as (
    select
        territory_id,
        region,
        territory_group,
        country_region_code
    from {{ ref('stg_sales_territory') }}
),

cr as (
    select
        CountryRegionCode,
        Name as country
    from Person.CountryRegion
)

select
    t.territory_id       as SalesTerritoryKey,
    cr.country           as Country,
    t.territory_group    as [Group],
    t.region             as Region
from t
left join cr
    on t.country_region_code = cr.CountryRegionCode;