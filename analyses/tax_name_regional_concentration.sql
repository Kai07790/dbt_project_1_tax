-- Q3-1. 주요 세목의 지역별 세수 집중도 비교
--   2020~2024년 누적 기준 국세·지방세의 주요 세목별 세수는 어느 지역에 집중되어 있으며,
--   상위 3개 지역의 세수 집중도는 세목 간 어떻게 다른가?

WITH tax_revenue AS (
    SELECT *
    FROM {{ ref('fct_tax_revenue') }}
    WHERE
        tax_name IN ('소득세', '법인세', '부가가치세', '취득세', '지방소득세', '지방소비세')
),

aggregated AS (
    SELECT
        tax_type,
        tax_name,
        region,
        SUM(tax_amount) AS tax_amount
    FROM tax_revenue    
    GROUP BY
        tax_type,
        tax_name,
        region
),

calculated AS (
    SELECT
        *,
        tax_amount / total_tax_amount AS region_share_of_tax
    FROM (
        SELECT
            *,
            SUM(tax_amount) OVER (PARTITION BY tax_type, tax_name) AS total_tax_amount
        FROM aggregated
        )
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY tax_type, tax_name ORDER BY tax_amount DESC, region) AS region_rank
    FROM calculated
    QUALIFY region_rank <= 3
)

SELECT
    tax_type,
    tax_name,
    region,
    tax_amount,
    total_tax_amount,
    ROUND(region_share_of_tax, 3) AS region_share_of_tax,
    region_rank,
    ROUND(SUM(region_share_of_tax) OVER (PARTITION BY tax_type, tax_name), 3) AS top3_region_share
FROM ranked
ORDER BY
    tax_type,
    top3_region_share DESC,
    tax_name,
    region_rank,
    region
    
