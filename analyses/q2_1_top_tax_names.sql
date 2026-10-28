-- Q2-1. 국세와 지방세에서 각각 어떤 세목이 큰 비중을 차지하는가?

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

