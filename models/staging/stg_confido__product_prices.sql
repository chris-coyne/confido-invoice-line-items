-- Contracted price per product, optionally scoped by customer, DC and date.
-- Not used by the mart: the mart reports what was actually invoiced, and
-- product_prices is what should have been invoiced.
--
-- Also checked as a tiebreaker for ambiguous product resolution and it doesn't
-- help - the five products competing for item_remote_id '2' each have the same
-- two price rows on the same 2020-01-01 effective date.
--
-- Staged rather than dropped because invoiced-vs-contracted variance is an
-- obvious next model.

with source as (
    select * from {{ source('confido', 'product_prices') }}
),

renamed as (
    select
        id as product_price_id,
        product_id,
        global_customer_id,
        distribution_center_id,
        forecast_version_id,
        amount as price_amount,
        effective_at,
        _updated_at as source_updated_at
    from source
)

select * from renamed
