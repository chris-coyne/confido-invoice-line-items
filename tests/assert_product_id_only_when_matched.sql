-- product_id is populated if and only if the match was unambiguous.

select
    invoice_line_item_id,
    product_match_status,
    product_id
from {{ ref('fct_invoice_line_items') }}
where (product_match_status = 'matched' and product_id is null)
    or (product_match_status <> 'matched' and product_id is not null)
