SELECT
    tax_year,
    tax_type,
    tax_name,
    tax_amount,
    tax_share_in_type,
    tax_rank_in_type,
    tax_amount_yoy_change,
    tax_amount_yoy_change_rate
FROM {{ ref('rpt_tax_revenue_by_tax_name') }}
WHERE tax_rank_in_type <= 3
ORDER BY
    tax_year,
    tax_type,
    tax_rank_in_type

