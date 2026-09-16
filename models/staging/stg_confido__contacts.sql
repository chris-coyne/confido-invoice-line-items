-- Accounting-system contacts. Bridges customer_remote_id on an invoice to a
-- Confido global customer and (eventually) a distribution center.

with source as (
    select * from {{ source('confido', 'contacts') }}
),

renamed as (
    select
        id as contact_id,
        global_customer_id,
        distribution_center_id,
        company_detail_id,
        remote_id as contact_remote_id,
        parent_remote_id as parent_contact_remote_id,
        name as contact_name,
        _updated_at as source_updated_at
    from source
)

select * from renamed
