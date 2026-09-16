-- Tenant registry. company_detail_id sits on every other table; this extract
-- only contains one tenant (id 40).

with source as (
    select * from {{ source('confido', 'company_details') }}
),

renamed as (
    select
        id as company_detail_id,
        name as company_name,
        merge_uuid,
        muffin_organization_id,
        forecast_end_day_of_week,
        prevent_customer_remapping,
        _updated_at as source_updated_at
    from source
)

select * from renamed
