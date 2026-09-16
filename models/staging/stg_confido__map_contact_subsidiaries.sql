-- Not used by the mart, and worth a warning: invoices.subsidiary_id looks like a
-- cleaner path to the customer than the messy text customer_remote_id, but this
-- table has 47 rows sharing a single distinct subsidiary_id. Joining on it turns
-- 2,516 invoices into 118,252 rows. Customer resolution goes through
-- customer_remote_id -> contacts only.

with source as (
    select * from {{ source('confido', 'map_contact_subsidiaries') }}
),

renamed as (
    select
        id as contact_subsidiary_map_id,
        contact_id,
        subsidiary_id,
        _updated_at as source_updated_at
    from source
)

select * from renamed
