-- Q2-1. 주요 세목의 규모 및 증감 분석
--   1. 국세·지방세에서 세수 규모가 큰 주요 세목은 무엇인가?
--   2. 연도별 세수 증감액의 절댓값이 가장 큰 세목은 무엇이며, 증가·감소 양상은 어떻게 다른가?

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

