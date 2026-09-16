with source as (
    select * from {{ source('confido', 'confido_distribution_centers') }}
),

renamed as (
    select
        id as distribution_center_id,
        _uuid as distribution_center_uuid,
        global_customer_id,
        company_detail_id,
        name as distribution_center_name,
        muffin_location_id,
        _updated_at as source_updated_at
    from source
)

select * from renamed
