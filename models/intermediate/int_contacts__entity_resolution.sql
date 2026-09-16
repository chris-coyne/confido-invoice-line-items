-- Resolves an accounting-system contact to Confido's global customer and
-- distribution center.
--
-- Two contacts are children of another contact and have no global_customer_id of
-- their own, so they inherit the parent's. The hierarchy is one level deep, so a
-- single self-join is enough. Inherited matches are flagged rather than hidden.

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
        contacts.contact_id,
        contacts.contact_remote_id,
        contacts.contact_name,
        contacts.global_customer_id as own_global_customer_id,
        parent.global_customer_id as parent_global_customer_id,
        contacts.distribution_center_id
    from contacts
    left join contacts as parent
        on contacts.parent_contact_remote_id = parent.contact_remote_id
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
    resolved.contact_id,
    resolved.contact_remote_id,
    resolved.contact_name,
    resolved.global_customer_id,
    global_customers.global_customer_name,
    global_customers.is_distributor,
    resolved.customer_match_status,

    -- null on every row today; contacts.distribution_center_id is unpopulated upstream
    resolved.distribution_center_id,
    distribution_centers.distribution_center_name
from resolved
left join global_customers
    on global_customers.global_customer_id = resolved.global_customer_id
left join distribution_centers
    on distribution_centers.distribution_center_id = resolved.distribution_center_id
