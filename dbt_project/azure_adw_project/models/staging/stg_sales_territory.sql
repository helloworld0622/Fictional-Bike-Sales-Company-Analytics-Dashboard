{{ config(materialized='view') }}

select
    TerritoryID         as territory_id,
    Name                as region,
    [Group]             as territory_group,
    CountryRegionCode   as country_region_code
from Sales.SalesTerritory;