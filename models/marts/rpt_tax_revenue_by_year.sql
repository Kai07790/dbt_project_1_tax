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

local_share AS (
    SELECT
        *,
        tax_amount_local / tax_amount_total AS tax_share_local
    FROM tax_total
),

share_change AS (
    SELECT
        *,
        (
            tax_share_local 
            - LAG(tax_share_local) OVER (ORDER BY tax_year)
        ) * 100 AS tax_share_local_yoy_pp
    FROM local_share
),

final AS (
    SELECT
        tax_year,
        tax_amount_national,
        tax_amount_local,
        tax_amount_total,
        tax_share_local,
        tax_share_local_yoy_pp
    FROM share_change
)

SELECT *
FROM final