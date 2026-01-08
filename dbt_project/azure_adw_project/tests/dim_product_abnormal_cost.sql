select *
from {{ ref('dim_product') }}
where [Standard Cost] > 3 * [List Price]