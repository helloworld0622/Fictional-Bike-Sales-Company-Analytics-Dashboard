{{ config(materialized='view') }}

select
    CustomerID    as customer_id,
    PersonID      as person_id,
    StoreID       as store_id,
    TerritoryID   as territory_id,
    AccountNumber as account_number
from Sales.Customer;