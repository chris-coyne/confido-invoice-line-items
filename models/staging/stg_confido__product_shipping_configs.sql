-- Which product actually ships when another is ordered, scoped by customer, DC
-- and date. Not used by the mart: this is fulfilment, and the mart is billing.
-- Only 3 of its 61 rows even touch a product that's linked to an item.
--
-- This is the one source table with no id column. Its grain is the five columns
-- below (61 distinct combinations across 61 rows), so we hash them into a
-- surrogate key to give the model a testable primary key like everything else.

with source as (
    select * from {{ source('confido', 'product_shipping_configs') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'product_id',
            'global_customer_id',
            'distribution_center_id',
            'forecast_version_id',
            'effective_at'
        ]) }} as product_shipping_config_id,

        product_id,
        shipping_product_id,
        global_customer_id,
        distribution_center_id,
        forecast_version_id,
        effective_at,
        _updated_at as source_updated_at
    from source
)

select * from renamed
