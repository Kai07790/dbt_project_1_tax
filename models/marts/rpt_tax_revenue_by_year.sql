WITH tax_revenue AS (
    SELECT *
    FROM {{ ref('fct_tax_revenue') }}
),

aggregated AS (
    SELECT
        tax_year,
        SUM(
            CASE WHEN tax_type = '국세' THEN tax_amount END
        ) AS tax_amount_national,
        SUM(
            CASE WHEN tax_type = '지방세' THEN tax_amount END
        ) AS tax_amount_local
    FROM tax_revenue
    GROUP BY tax_year
),

tax_total AS (
    SELECT
        *,
        tax_amount_national + tax_amount_local AS tax_amount_total
    FROM aggregated
),

local_ratio AS (
    SELECT
        *,
        ROUND(SAFE_DIVIDE(tax_amount_local, tax_amount_total), 4) AS tax_ratio_local
    FROM tax_total
),

ratio_change AS (
    SELECT
        *,
        ROUND(
            (
                tax_ratio_local 
                - LAG(tax_ratio_local) OVER (ORDER BY tax_year)
            ) * 100, 2
        ) AS tax_ratio_local_yoy_pp
    FROM local_ratio
),

final AS (
    SELECT
        tax_year,
        tax_amount_national,
        tax_amount_local,
        tax_amount_total,
        tax_ratio_local,
        tax_ratio_local_yoy_pp
    FROM ratio_change
)

SELECT *
FROM final