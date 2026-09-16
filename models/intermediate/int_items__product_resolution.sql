-- Resolves an accounting-system item to a Confido product.
--
-- products.item_id is many-to-one against items, so joining products straight onto
-- invoice lines fans 2,527 rows out to 5,853 and inflates revenue by 58%. This model
-- collapses to one row per item first and only hands back a product_id when there is
-- exactly one candidate, so the mart can't fan out.

with items as (
    select * from {{ ref('stg_confido__items') }}
),

products as (
    select * from {{ ref('stg_confido__products') }}
    where item_id is not null
),

candidates as (
    select
        i.item_id,
        count(p.product_id)::number(38,0) as product_candidate_count,
        -- only used when the count is 1
        min(p.product_id) as matched_product_id
    from items i
    left join products p on p.item_id = i.item_id
    group by i.item_id
),

resolved as (
    select
        i.item_id,
        i.item_remote_id,
        i.item_name,
        c.product_candidate_count,

        case
            when c.product_candidate_count = 1 then 'matched'
            when c.product_candidate_count > 1 then 'ambiguous'
            else 'unmapped'
        end as product_match_status,

        case
            when c.product_candidate_count = 1 then c.matched_product_id
        end as product_id
    from items i
    join candidates c on c.item_id = i.item_id
)

select
    r.item_id,
    r.item_remote_id,
    r.item_name,
    r.product_id,
    p.product_name,
    p.product_upc,
    p.product_type,
    r.product_match_status,
    r.product_candidate_count
from resolved r
left join products p on p.product_id = r.product_id
