select
    fs.ResellerKey
from {{ ref('fact_sales') }} fs
left join {{ ref('dim_reseller') }} dr
    on fs.ResellerKey = dr.ResellerKey
where
    fs.ResellerKey <> -1
    and dr.ResellerKey is null;