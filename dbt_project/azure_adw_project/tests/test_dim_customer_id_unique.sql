with dup as (
    select
        CustomerID,
        count(*) as cnt
    from {{ ref('dim_customer') }}
    group by CustomerID
    having count(*) > 1
)
select *
from dup;