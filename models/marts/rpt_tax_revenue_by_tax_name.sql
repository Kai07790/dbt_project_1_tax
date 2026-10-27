WITH tax_revenue AS (
    SELECT
        tax_year,
        tax_type,
        tax_name,
        SUM(tax_amount) AS tax_amount
    FROM {{ ref('fct_tax_revenue') }}
    GROUP BY
        tax_year,
        tax_type,
        tax_name
),

tax_composition AS (
    SELECT
        *,
        tax_amount / SUM(tax_amount) OVER (PARTITION BY tax_year, tax_type) AS tax_share_in_type,
        RANK() OVER (PARTITION BY tax_year, tax_type ORDER BY tax_amount DESC) AS tax_rank_in_type
    FROM tax_revenue
),

tax_yoy_change AS (
    SELECT
        *,
        tax_amount - LAG(tax_amount) OVER (PARTITION BY tax_type, tax_name ORDER BY tax_year) AS tax_amount_yoy_change
    FROM tax_composition
),

tax_yoy_change_rate AS (
    SELECT
        *,
        tax_amount_yoy_change
        / LAG(tax_amount) OVER (PARTITION BY tax_type, tax_name ORDER BY tax_year) AS tax_amount_yoy_change_rate
    FROM tax_yoy_change
),

final AS (
    SELECT
        tax_year,
        tax_type,
        tax_name,
        tax_amount,
        tax_share_in_type,
        tax_rank_in_type,
        tax_amount_yoy_change,
        tax_amount_yoy_change_rate
    FROM tax_yoy_change_rate
)

SELECT *
FROM final




