-- Invoice line items. This is the grain the final mart is built on.

with source as (
    select * from {{ source('confido', 'invoice_items') }}
),

renamed as (
    select
        id as invoice_line_item_id,
        invoice_id,
        item_remote_id,

        -- total_amount is the billed figure and is taken as-is. It disagrees with
        -- quantity * unit_price on 1,726 of 2,527 rows, so don't recompute it.
        -- Stored as FLOAT upstream, which isn't a money type - sums aren't reproducible
        -- and the values carry float tails (2020.4307500081). Rounded to cents here.
        total_amount::number(38,2) as amount,
        quantity,
        unit_price::number(38,6) as unit_price,

        _updated_at as source_updated_at
    from source
)

select * from renamed
