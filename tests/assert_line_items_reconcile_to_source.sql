-- Catches an accidental fanout: the mart should never drop, duplicate or re-value
-- a source line. Source side is rounded the same way staging rounds it, so this is
-- an exact comparison.

with source as (
    select
        count(*) as lines,
        sum(total_amount::number(38,2)) as dollars
    from {{ source('confido', 'invoice_items') }}
),

mart as (
    select
        count(*) as lines,
        sum(amount) as dollars
    from {{ ref('fct_invoice_line_items') }}
)

select
    s.lines as source_lines,
    m.lines as mart_lines,
    s.dollars as source_dollars,
    m.dollars as mart_dollars
from source s
cross join mart m
where s.lines <> m.lines
    or s.dollars <> m.dollars
