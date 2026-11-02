WITH tax_revenue AS (
    SELECT *
    FROM {{ ref('fct_tax_revenue') }}
),

aggregated_tax AS (
    SELECT
        tax_year,
        region,
        SUM(IF(tax_type = '국세', tax_amount, NULL)) AS tax_amount_national,
        SUM(IF(tax_type = '지방세', tax_amount, NULL)) AS tax_amount_local,
        SUM(IF(tax_name = '취득세', tax_amount, NULL)) AS tax_amount_acquisition,
        SUM(IF(tax_name = '지방소비세', tax_amount, NULL)) AS tax_amount_local_consumption
    FROM tax_revenue
    GROUP BY
        tax_year,
        region
),

joined_population AS (
    SELECT
        t.*,
        CASE
            WHEN t.region IN ('서울', '경기', '인천') THEN '수도권'
            ELSE '비수도권'
        END AS region_type,
        p.population_count
    FROM aggregated_tax AS t
    LEFT JOIN {{ ref('int_tax_admin__population') }} AS p
        ON t.tax_year = p.population_year
        AND t.region = p.region
),

final AS (
    SELECT
        tax_year,
        region,
        region_type,
        population_count,
        tax_amount_national,
        tax_amount_local,
        tax_amount_acquisition,
        tax_amount_local_consumption
    FROM joined_population
)

SELECT *
FROM final