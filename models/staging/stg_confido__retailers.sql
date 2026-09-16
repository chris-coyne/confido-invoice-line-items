-- Retailer reference data from the Muffin platform. Not used by the mart -
-- nothing joins an invoice to a retailer. The only linkage available is
-- global_customers.name = retailers.name, which hits 30 of 156 customers, and
-- the shared _uuid column matches on zero rows. Name matching across systems
-- against a 3,008 row table breaks the first time someone renames a record.
--
-- Retailers also aren't one of the three entities the brief asks for.

with source as (
    select * from {{ source('confido', 'retailers') }}
),

renamed as (
    select
        id as retailer_id,
        _uuid as retailer_uuid,
        company_detail_id,
        muffin_account_id,
        muffin_chain_id,
        name as retailer_name,
        is_custom,
        _updated_at as source_updated_at
    from source
)

select * from renamed
