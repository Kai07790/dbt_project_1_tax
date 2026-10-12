WITH national AS (
    SELECT *
    FROM {{ ref('int_tax_admin__national_tax') }}
),

local AS (
    SELECT *
    FROM {{ ref('int_tax_admin__local_tax') }}
),

combined AS (
    SELECT
        tax_year,
        region,
        '국세' AS tax_type,
        tax_name,
        tax_amount
    FROM national

    UNION ALL

    SELECT
        tax_year,
        region,
        '지방세' AS tax_type,
        tax_name,
        tax_amount
    FROM local
),

final AS (
    SELECT *
    FROM combined
)

SELECT *
FROM final

