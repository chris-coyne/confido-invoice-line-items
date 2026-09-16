-- Invoice line items with Confido internal entities attached.
--
-- Grain: one row per invoice line item, same as the source. Product and customer
-- come from the intermediate models, which are each unique on their join key, so
-- nothing here can fan out.
--
-- Internal ids are null where the external record can't be resolved, and the
-- *_match_status columns say which case you're looking at.

with invoice_items as (
    select * from {{ ref('stg_confido__invoice_items') }}
),

invoices as (
    select * from {{ ref('stg_confido__invoices') }}
),

items as (
    select * from {{ ref('int_items__product_resolution') }}
),

contacts as (
    select * from {{ ref('int_contacts__entity_resolution') }}
),

companies as (
    select * from {{ ref('stg_confido__company_details') }}
)

select
    li.invoice_line_item_id,
    li.invoice_id,
    inv.invoice_number,
    inv.invoice_created_at,
    inv.invoice_paid_on_date,

    li.amount,
    inv.currency_code,

    li.item_remote_id,
    it.item_name,
    it.product_id,
    it.product_name,
    it.product_upc,
    it.product_match_status,
    it.product_candidate_count,

    inv.customer_remote_id,
    ct.global_customer_id,
    ct.global_customer_name,
    ct.is_distributor,
    -- no matching contact at all, as opposed to a contact that maps to nothing
    coalesce(ct.customer_match_status, 'unresolved_remote_id') as customer_match_status,

    ct.distribution_center_id,
    ct.distribution_center_name,

    inv.company_detail_id,
    co.company_name,

    greatest(li.source_updated_at, inv.source_updated_at) as source_updated_at

-- inner join: every line has a parent invoice, and the relationships test on
-- stg_confido__invoice_items stops the build if that ever changes
from invoice_items li
join invoices inv on inv.invoice_id = li.invoice_id
left join items it on it.item_remote_id = li.item_remote_id
left join contacts ct on ct.contact_remote_id = inv.customer_remote_id
left join companies co on co.company_detail_id = inv.company_detail_id
