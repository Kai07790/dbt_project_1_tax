WITH population AS (
    SELECT *
    FROM {{ ref('stg_tax_admin__population') }}
),

region_normalized AS (
    SELECT
        population_year,
        CASE
            WHEN region IN ('충남', '세종') THEN '충남·세종'
            ELSE region
        END AS region,
        population_count
    FROM population
),

aggregated AS (
    SELECT
        population_year,
        region,
        SUM(population_count) AS population_count
    FROM region_normalized
    GROUP BY
        population_year,
        region
),

final AS (
    SELECT *
    FROM aggregated
)

SELECT *
FROM final