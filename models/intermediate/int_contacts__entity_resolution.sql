-- Resolves an accounting-system contact to Confido's global customer and
-- distribution center.
--
-- Two contacts are children of another contact and have no global_customer_id of
-- their own, so they take the parent's. Hierarchy is one level deep, so a single
-- self-join covers it. Inherited matches get their own status.

with contacts as (
    select * from {{ ref('stg_confido__contacts') }}
),

global_customers as (
    select * from {{ ref('stg_confido__global_customers') }}
),

distribution_centers as (
    select * from {{ ref('stg_confido__distribution_centers') }}
),

with_parent as (
    select
        c.contact_id,
        c.contact_remote_id,
        c.contact_name,
        c.global_customer_id as own_global_customer_id,
        p.global_customer_id as parent_global_customer_id,
        c.distribution_center_id
    from contacts c
    left join contacts p on c.parent_contact_remote_id = p.contact_remote_id
),

resolved as (
    select
        *,
        coalesce(own_global_customer_id, parent_global_customer_id) as global_customer_id,
        case
            when own_global_customer_id is not null then 'matched'
            when parent_global_customer_id is not null then 'matched_via_parent'
            else 'contact_not_mapped'
        end as customer_match_status
    from with_parent
)

select
    r.contact_id,
    r.contact_remote_id,
    r.contact_name,
    r.global_customer_id,
    gc.global_customer_name,
    gc.is_distributor,
    r.customer_match_status,

    -- null on every row today; contacts.distribution_center_id is unpopulated upstream
    r.distribution_center_id,
    dc.distribution_center_name
from resolved r
left join global_customers gc on gc.global_customer_id = r.global_customer_id
left join distribution_centers dc on dc.distribution_center_id = r.distribution_center_id
