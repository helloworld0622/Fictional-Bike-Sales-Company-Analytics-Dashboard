select *
from {{ ref('fact_sales') }}
where [Unit Price] < 0