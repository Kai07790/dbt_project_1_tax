WITH metro AS (
    SELECT *
    FROM {{ ref('stg_tax_admin__local_tax_metro') }}
),

provincial AS (
    SELECT *
    FROM {{ ref('stg_tax_admin__local_tax_provincial') }}
),

combined AS (
    SELECT
        tax_year,
        region,
        tax_category_level_2 AS tax_name,
        tax_amount
    FROM metro

    UNION ALL

    SELECT
        tax_year,
        region,
        tax_category_level_2 AS tax_name,
        tax_amount
    FROM provincial
),

filtered AS (
    SELECT *
    FROM combined
    WHERE tax_name NOT IN ('도축세', '도시계획세', '과년도수입')
),

region_normalized AS (
    SELECT
        tax_year,
        CASE
            WHEN region IN ('충남', '세종') THEN '충남·세종'
            ELSE region
        END AS region,
        tax_name,
        tax_amount
    FROM filtered
),

aggregated AS (
    SELECT
        tax_year,
        region,
        tax_name,
        SUM(tax_amount) AS tax_amount
    FROM region_normalized
    GROUP BY
        tax_year,
        region,
        tax_name
),

final AS (
    SELECT *
    FROM aggregated
)

SELECT *
FROM final