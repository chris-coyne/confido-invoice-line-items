-- The mart must never drop, duplicate or re-value a source line. This is the test
-- that catches an accidental fanout, which is the easiest mistake to make here.

with source as (
    select
        count(*) as lines,
        sum(total_amount) as dollars
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
    or abs(s.dollars - m.dollars) > 0.01
