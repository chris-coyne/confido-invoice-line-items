-- Confido's product catalog. item_id is many-to-one against items, which is why
-- product resolution needs int_items__product_resolution and not a direct join.

with source as (
    select * from {{ source('confido', 'products') }}
),

renamed as (
    select
        id as product_id,
        _uuid as product_uuid,
        item_id,
        product_family_id,
        company_detail_id,
        name as product_name,
        type as product_type,
        upc as product_upc,
        cleaned_upc as product_cleaned_upc,
        internal_item_number,
        ship_with_product_relationship_id,
        updated_at as product_updated_at,
        _updated_at as source_updated_at
    from source
)

select * from renamed
