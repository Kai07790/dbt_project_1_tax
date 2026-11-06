-- Q2-1. 주요 세목의 규모 및 증감 분석
--   1. 연도별 국세·지방세에서 세수 규모가 큰 주요 세목은 무엇인가?
--   2. 연도별 국세·지방세에서 세수 증가액과 감소액이 가장 큰 세목은 각각 무엇인가?

WITH tax_revenue AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY tax_year, tax_type ORDER BY tax_amount DESC) AS tax_amount_rank,
        CASE
            WHEN tax_amount_yoy_change > 0
            THEN RANK() OVER (PARTITION BY tax_year, tax_type, SIGN(tax_amount_yoy_change) ORDER BY tax_amount_yoy_change DESC)
        END AS tax_yoy_increase_rank,
        CASE
            WHEN tax_amount_yoy_change < 0
            THEN RANK() OVER (PARTITION BY tax_year, tax_type, SIGN(tax_amount_yoy_change) ORDER BY tax_amount_yoy_change)
        END AS tax_yoy_decrease_rank
    FROM {{ ref('rpt_tax_revenue_by_tax_name') }}
)

SELECT
    tax_year,
    tax_type,
    tax_name,
    tax_amount,
    tax_share_in_type,
    tax_amount_yoy_change,
    tax_amount_yoy_change_rate,
    tax_amount_rank,
    tax_yoy_increase_rank,
    tax_yoy_decrease_rank
FROM tax_revenue
WHERE
    tax_amount_rank <= 3
    OR tax_yoy_increase_rank <= 3
    OR tax_yoy_decrease_rank <= 3
ORDER BY
    tax_year,
    tax_type,
    tax_amount_rank

