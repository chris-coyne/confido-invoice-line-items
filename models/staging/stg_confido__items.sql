-- Accounting-system items. Bridges item_remote_id on a line to Confido products.

with source as (
    select * from {{ source('confido', 'items') }}
),

renamed as (
    select
        id as item_id,
        company_detail_id,
        remote_id as item_remote_id,
        name as item_name,
        _updated_at as source_updated_at
    from source
)

select * from renamed
