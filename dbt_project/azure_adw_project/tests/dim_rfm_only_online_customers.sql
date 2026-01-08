select r.*
from {{ ref('dim_rfm') }} r
left join {{ ref('dim_customer') }} c
  on r.CustomerKey = c.CustomerKey
where r.CustomerKey = -1