WITH metro AS (
    SELECT *
    FROM {{ ref('stg_tax_admin__local_tax_metro') }}
),

provincial AS(
    SELECT *
    FROM {{ ref('stg_tax_admin__local_tax_provincial') }}
),

combined AS(
    SELECT
        tax_year,
        region,
        tax_category_level_1,
        tax_category_level_2,
        tax_amount
    FROM metro
    UNION ALL
    SELECT
        tax_year,
        region,
        tax_category_level_1,
        tax_category_level_2,
        tax_amount
    FROM provincial
),

region_normalized AS(
    SELECT
        tax_year,
        region,
        tax_category_level_1,
        tax_category_level_2,
        tax_amount
    FROM combined
),

final AS(
    SELECT *
    FROM region_normalized
)

SELECT *
FROM final

