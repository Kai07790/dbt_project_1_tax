WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'national_tax') }}
),

renamed AS(
    SELECT
        `세목별1` AS tax_category_level_1,
        `세목별2` AS tax_category_level_2,
        `세목별3` AS tax_category_level_3,
        `세목별4` AS tax_category_level_4,
        `세목별5` AS tax_category_level_5,
        `세목별6` AS tax_category_level_6,
        SAFE_CAST(`연도` AS INT64) AS tax_year,
        `지방청` AS regional_tax_office,
        `지역` AS region,
        `금액 단위` AS value_type,
        SAFE_CAST(`세수액` AS FLOAT64) AS tax_value
    FROM source
)

SELECT *
FROM renamed