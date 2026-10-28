-- Q2-2. 2020~2024년 동안 세목별 구성비는 어떻게 변화했는가?

WITH tax_share_trend AS (
    SELECT
        tax_type,
        tax_name,
        MAX(IF(tax_year = 2020, tax_share_in_type, NULL))  AS share_2020,
        MAX(IF(tax_year = 2021, tax_share_in_type, NULL)) AS share_2021,
        MAX(IF(tax_year = 2022, tax_share_in_type, NULL)) AS share_2022,
        MAX(IF(tax_year = 2023, tax_share_in_type, NULL)) AS share_2023,
        MAX(IF(tax_year = 2024, tax_share_in_type, NULL)) AS share_2024
    FROM {{ ref('rpt_tax_revenue_by_tax_name') }}
    GROUP BY
        tax_type,
        tax_name
)

SELECT
    *,
    ROUND((share_2024 - share_2020) * 100, 2) AS share_change_2020_2024_pp
FROM tax_share_trend
ORDER BY
    tax_type,
    ABS(share_2024 - share_2020) DESC,
    tax_name



    