# Confido invoice line items

Turns the raw `invoices` / `invoice_items` tables into `fct_invoice_line_items` — one row
per invoice line with Confido's product, global customer and distribution center attached.
The source tables come from an external accounting system and only carry its remote ids,
so most of the work is resolving those to internal entities and being honest where it
isn't possible.

## The output

One row per `invoice_items.id`. **2,527 rows, $8,329,402.21** — same rows and same money
as the source. Where an id can't be resolved the internal id is null and a status column
says why.

Product resolves on 1,651 lines (~$6.9M). 854 lines (~$1.4M) are ambiguous, and 22 (~$81k)
map to nothing because they're fees and discounts rather than goods.

Customer resolves on 911 lines (~$6.7M), 10 of those inherited from a parent contact.
1,603 lines (~$1.6M) point at ids that don't exist on the Confido side, and 13 hit a
contact that has no customer mapped to it.

810 lines (~$5.6M, 67%) resolve on both sides. Filter on the statuses for clean
product-by-customer revenue; use everything for AR totals and it still ties to source.

Quantity is excluded — not asked for, and it disagrees with `total_amount / unit_price` on
most rows.

## Running it

```bash
cp .env.example .env     # fill in your Snowflake account, user, role, schema, password
set -a && source .env && set +a
dbt deps
dbt build
```

`profiles.yml` sits in the repo root and dbt reads it from there. Connection details come
from the environment, so nothing environment-specific is committed. 16 models, 124 tests.

## Layout

```
staging/       one model per source table, renames and casts, no joins
intermediate/  the two resolution problems, each collapsed to a unique key
marts/         fct_invoice_line_items
tests/         the reconciliation check and one invariant
```

All 13 source tables are staged. The five nothing uses have a header comment saying what I
checked them for and why I dropped them.

## Decisions

**Ambiguous products get a null, not a guess.** `products.item_id` is many-to-one against
`items`, so joining products onto lines turns 2,527 rows into 5,853 and inflates revenue
58%. One item ("Yogurt", 824 lines) maps to five products and nothing separates them — I
checked type, UPC, internal item number, product family, prices and product relationships.
So the intermediate model only returns a product when there's exactly one candidate.

**Unresolvable customers stay in.** 1,603 invoices point at four synthetic
`GENERATED_<hash>` ids that appear nowhere else in the database. Dropping them loses $1.57M
and two thirds of the invoices.

**Child contacts inherit their parent's customer.** Two contacts have none of their own and
both point at KeHE. Flagged `matched_via_parent`; resolves 7 more invoices.

**Money is rounded to cents here, not upstream.** `total_amount` is a FLOAT carrying tails
like `2020.4307500081`. Cast to `NUMBER(38,2)`, which rounds 1,738 rows and moves the total
~$0.13. `paid_on_date` became a DATE — it was midnight on every row.

**Currency left alone.** Null on 1,738 of 2,516 invoices; defaulting to USD would be
inventing something about money.

**`subsidiary_id` is a trap.** Looks like a cleaner path to the customer, but
`map_contact_subsidiaries` has 47 rows and one distinct `subsidiary_id` — joining on it
turns 2,516 invoices into 118,252.

## Tests

124, all passing. The two that matter: `assert_line_items_reconcile_to_source` checks rows
and dollars against the raw source and fails on any fanout, and the mart has an enforced
contract over all 24 columns so a rename or retype breaks the build rather than a consumer.

Every model has a column tested unique and not null. `invoices.number` deliberately isn't —
two invoices really do share "REPAY INVOICE REALLY".

## Known gaps

**Distribution centers are always null.** `contacts.distribution_center_id` is null on all
47 contacts. Name-matching to DCs gets zero hits; going via global customer gives 368 DCs
for 11 customers. The join is wired up and will populate when upstream does.

**Product 799 is named `<img src=1 onerror=prompt(1)>`** — an XSS probe in the catalog,
flowing through to `product_name`. Worth someone knowing, given this is headed external.

## With more time

- Ask whoever owns the sync whether the 854 ambiguous lines can be mapped properly.
- Snapshot `contacts` and `products` — both get remapped, which silently rewrites history.
- Incremental on the mart keyed on `source_updated_at`. Fine at 2,527 rows, not at 25M.
- Source freshness, once I know how often the sync runs.
- An invoice-header model. Most of the joins are already here.
