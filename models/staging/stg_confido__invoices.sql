-- Invoice headers synced in from the external accounting system.
-- customer_remote_id points at that system, not at a Confido entity.

with source as (
    select * from {{ source('confido', 'invoices') }}
),

renamed as (
    select
        id as invoice_id,
        company_detail_id,
        customer_remote_id,
        number as invoice_number,
        currency as currency_code,
        created_at as invoice_created_at,
        paid_on_date::date as invoice_paid_on_date,

        -- kept for traceability, but subsidiary_id is not a usable join key.
        -- see stg_confido__map_contact_subsidiaries for the reason.
        subsidiary_id,
        check_remit_item_id,

        _updated_at as source_updated_at
    from source
)

select * from renamed
