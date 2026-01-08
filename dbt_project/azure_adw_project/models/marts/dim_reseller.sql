{{ config(materialized='view') }}

with base as (
    select
        ResellerKey,
        Reseller,
        [Business Type]       as BusinessTypeCode,
        City,
        [State-Province],
        [Country-Region],
        [Postal Code]
    from {{ ref('stg_reseller') }}
)

select
    -- 维度主键：ResellerKey（int）
    b.ResellerKey                       as ResellerKey,

    -- 显示用 ID：AW + 8 位零填充
    'AW' + right('00000000' + cast(b.ResellerKey as varchar(8)), 8)
                                        as [Reseller ID],

    b.Reseller                          as [Reseller],

    -- 业务类型映射
    case b.BusinessTypeCode
        when 'BS' then 'Specialty Bike Shop'
        when 'BM' then 'Value Added Reseller'
        when 'OS' then 'Warehouse'
        else '[Not Applicable]'
    end                                 as [Business Type],

    b.City                              as City,
    b.[State-Province]                  as [State-Province],
    b.[Country-Region]                  as [Country-Region],
    b.[Postal Code]                     as [Postal Code]
from base b;