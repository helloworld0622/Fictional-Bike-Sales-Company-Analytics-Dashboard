{{ config(materialized='view') }}

with c as (
    -- Get the basic fields from staging + AccountNumber
    select
        customer_id,
        person_id,
        store_id,
        account_number
    from {{ ref('stg_customer') }}
),
p as (
    select
        BusinessEntityID,
        FirstName,
        LastName
    from Person.Person
),
-- compress the address of each BusinessEntityID
addr_dedup as (
    select
        bea.BusinessEntityID,
        a.City,
        a.PostalCode,
        sp.Name as StateProvince,
        cr.Name as CountryRegion,
        row_number() over (
            partition by bea.BusinessEntityID
            order by
                case at.Name
                    when 'Home' then 1       -- Deduplicate addresses by prioritizing Home, then Main Office
                    when 'Main Office' then 2
                    else 3
                end,
                a.AddressID                 
        ) as rn
    from Person.BusinessEntityAddress bea
    join Person.Address a
        on bea.AddressID = a.AddressID
    join Person.AddressType at
        on bea.AddressTypeID = at.AddressTypeID
    join Person.StateProvince sp
        on a.StateProvinceID = sp.StateProvinceID
    join Person.CountryRegion cr
        on sp.CountryRegionCode = cr.CountryRegionCode
),
addr as (
    -- Only retain the first address for each BusinessEntityID
    select
        BusinessEntityID,
        City,
        PostalCode,
        StateProvince,
        CountryRegion
    from addr_dedup
    where rn = 1
),

-- Only retain the PersonID
main_customers as (
    select
        -- CustomerKey：CustomerID（int）
        c.customer_id as CustomerKey,
        -- Customer ID used for business presentation
        c.account_number as CustomerID,
        -- Customer Name
        p.FirstName + ' ' + p.LastName as Customer,
        addr.City as City,
        addr.PostalCode as PostalCode,
        addr.StateProvince as StateProvince,
        addr.CountryRegion as [Country-Region]
    from c
    join p on c.person_id = p.BusinessEntityID
    left join addr on c.person_id = addr.BusinessEntityID
    where c.person_id is not null
),
-- Reserve a -1 line for Reseller
reseller_placeholder as (
    select
        -1 as CustomerKey,
        cast('[Not Applicable]' as nvarchar(20)) as CustomerID,
        cast('[Not Applicable]' as nvarchar(50)) as Customer,
        cast(null as nvarchar(50)) as City,
        cast(null as nvarchar(20)) as PostalCode,
        cast(null as nvarchar(50)) as StateProvince,
        cast(null as nvarchar(50)) as [Country-Region]
)
select
    CustomerKey,
    CustomerID,
    Customer,
    City,
    [Country-Region],
    PostalCode,
    StateProvince
from main_customers
union all
select
    CustomerKey,
    CustomerID,
    Customer,
    City,
    [Country-Region],
    PostalCode,
    StateProvince
from reseller_placeholder;