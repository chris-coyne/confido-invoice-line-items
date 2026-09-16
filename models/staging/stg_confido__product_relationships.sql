-- Parent/child product composition, e.g. a case and the units inside it.
--
-- Not used by the mart. Checked as a tiebreaker for ambiguous product
-- resolution: each of the five products competing for item_remote_id '2' is a
-- parent exactly once and a child never, so the hierarchy is symmetric and
-- tells us nothing about which one a line refers to.
--
-- Would matter if we ever needed unit-level rather than case-level revenue.

with source as (
    select * from {{ source('confido', 'product_relationships') }}
),

renamed as (
    select
        id as product_relationship_id,
        product_id as parent_product_id,
        child_product_id,
        quantity as child_quantity_per_parent,
        _updated_at as source_updated_at
    from source
)

select * from renamed
