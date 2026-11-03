-- Q3-2. 수도권 세수 집중도와 인구 비중 비교
--   2020~2024년 수도권의 국세·지방세 및 주요 지방세목(취득세·지방소비세)의 세수 비중은 인구 비중과 얼마나 차이가 있으며, 
--   그 격차는 연도별로 어떻게 변화했는가?

WITH tax_revenue AS (
    SELECT *
    FROM {{ ref('rpt_tax_revenue_by_region') }}
),

unpivoted AS (
    SELECT
        *
    FROM tax_revenue
    UNPIVOT(
        tax_amount
        FOR tax_category IN (
            tax_amount_national AS '국세',
            tax_amount_local AS '지방세',
            tax_amount_acquisition AS '취득세',
            tax_amount_local_consumption AS '지방소비세'
        )
    )
),

added_capital_shares AS (
    SELECT
        tax_category,
        tax_year,
        SUM(CASE WHEN region_type = '수도권' THEN tax_amount END) / SUM(tax_amount) AS tax_share_capital,
        SUM(CASE WHEN region_type = '수도권' THEN population_count END) / SUM(population_count) AS population_share_capital
    FROM unpivoted
    GROUP BY
        tax_category,
        tax_year
),

added_share_gap AS (
    SELECT
        *,
        share_gap_pp - LAG(share_gap_pp) OVER (PARTITION BY tax_category ORDER BY tax_year) AS share_gap_yoy_pp
    FROM (
        SELECT
            *,
            (tax_share_capital - population_share_capital) * 100 AS share_gap_pp
        FROM added_capital_shares
    )
)

SELECT
    tax_category,
    tax_year,
    tax_share_capital,
    population_share_capital,
    share_gap_pp,
    share_gap_yoy_pp
FROM added_share_gap
ORDER BY
    tax_category,
    tax_year

