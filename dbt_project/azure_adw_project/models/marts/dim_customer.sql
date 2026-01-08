{{ config(materialized='view') }}

with c as (
    -- 从 staging 拿到基础字段 + AccountNumber
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

-- 先把每个 BusinessEntityID 的地址压成一条
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
                    when 'Home' then 1       -- 优先 Home 地址
                    when 'Main Office' then 2
                    else 3
                end,
                a.AddressID                 -- 再按 AddressID 稍微固定一下顺序
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
    -- 只保留每个 BusinessEntityID 的第 1 条地址
    select
        BusinessEntityID,
        City,
        PostalCode,
        StateProvince,
        CountryRegion
    from addr_dedup
    where rn = 1
),

-- 只保留个人客户（PersonID 不为 null）
main_customers as (
    select
        -- ⭐ CustomerKey：直接用 CustomerID（int），保证唯一
        c.customer_id                               as CustomerKey,

        -- 对业务展示用的客户编号
        c.account_number                            as CustomerID,

        -- 客户姓名
        p.FirstName + ' ' + p.LastName              as Customer,

        -- 地址信息
        addr.City                                   as City,
        addr.PostalCode                             as PostalCode,
        addr.StateProvince                          as StateProvince,
        addr.CountryRegion                          as [Country-Region]
    from c
    join p
        on c.person_id = p.BusinessEntityID
    left join addr
        on c.person_id = addr.BusinessEntityID
    where c.person_id is not null
),

-- 给 Reseller / Unknown 预留一个 -1 行
reseller_placeholder as (
    select
        -1                                       as CustomerKey,
        cast('[Not Applicable]' as nvarchar(20)) as CustomerID,
        cast('[Not Applicable]' as nvarchar(50)) as Customer,
        cast(null as nvarchar(50))               as City,
        cast(null as nvarchar(20))               as PostalCode,
        cast(null as nvarchar(50))               as StateProvince,
        cast(null as nvarchar(50))               as [Country-Region]
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