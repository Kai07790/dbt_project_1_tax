WITH national_tax AS (
    SELECT *
    FROM {{ ref('stg_tax_admin__national_tax') }}
),

tax_office_cleaned AS (
    SELECT *
    FROM national_tax
    WHERE NOT (
        regional_tax_office = '중부청'
        AND region = '인천'
    )
),

tax_filtered AS (
    SELECT *
    FROM tax_office_cleaned
    WHERE effective_tax_category_name IN (
        '소득세',
        '법인세',
        '상속세',
        '증여세',
        '종합부동산세',
        '부가가치세',
        '개별(특별)소비세',
        '주세',
        '인지세',
        '증권거래세',
        '교육세',
        '교통·에너지·환경세',
        '농어촌특별세'
    )
),

selected AS (
    SELECT
        tax_year,
        region,
        effective_tax_category_name AS tax_name,
        tax_amount
    FROM tax_filtered
),

aggregated AS (
    SELECT
        tax_year,
        region,
        tax_name,
        SUM(tax_amount) AS tax_amount
    FROM selected
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

