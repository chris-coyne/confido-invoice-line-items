-- Resolves an accounting-system item to a Confido product.
--
-- products.item_id is many-to-one against items, so joining products straight onto
-- invoice lines fans 2,527 rows out to 5,853 and inflates revenue by 58%. This model
-- collapses to one row per item first and only hands back a product_id when there is
-- exactly one candidate, which makes that fanout impossible downstream.

with items as (
    select * from {{ ref('stg_confido__items') }}
),

products as (
    select * from {{ ref('stg_confido__products') }}
    where item_id is not null
),

candidates as (
    select
        items.item_id,
        count(products.product_id) as product_candidate_count,
        -- only used when the count is 1
        min(products.product_id) as matched_product_id
    from items
    left join products on products.item_id = items.item_id
    group by 1
),

resolved as (
    select
        items.item_id,
        items.item_remote_id,
        items.item_name,
        candidates.product_candidate_count,

        case
            when candidates.product_candidate_count = 1 then 'matched'
            when candidates.product_candidate_count > 1 then 'ambiguous'
            else 'unmapped'
        end as product_match_status,

        case
            when candidates.product_candidate_count = 1 then candidates.matched_product_id
        end as product_id
    from items
    join candidates on candidates.item_id = items.item_id
)

select
    resolved.item_id,
    resolved.item_remote_id,
    resolved.item_name,
    resolved.product_id,
    products.product_name,
    products.product_upc,
    products.product_type,
    resolved.product_match_status,
    resolved.product_candidate_count
from resolved
left join products on products.product_id = resolved.product_id
