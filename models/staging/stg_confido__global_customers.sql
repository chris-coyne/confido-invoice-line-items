with source as (
    select * from {{ source('confido', 'global_customers') }}
),

renamed as (
    select
        id as global_customer_id,
        _uuid as global_customer_uuid,
        company_detail_id,
        name as global_customer_name,
        is_distributor,
        _updated_at as source_updated_at
    from source
)

select * from renamed
