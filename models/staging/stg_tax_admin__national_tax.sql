WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'national_tax') }}
),

renamed AS(
    SELECT
        SAFE_CAST(`연도` AS INT64) AS tax_year,
        `지방청` AS regional_tax_office,
        `지역` AS region,
        `세목별1` AS tax_category_level_1,
        `세목별2` AS tax_category_level_2,
        `세목별3` AS tax_category_level_3,
        `세목별4` AS tax_category_level_4,
        `세목별5` AS tax_category_level_5,
        `세목별6` AS tax_category_level_6,   
        `금액 단위` AS value_type,
        SAFE_CAST(`세수액` AS FLOAT64) AS tax_value
    FROM source
),

added_surrogate_key AS(
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'tax_year',
            'regional_tax_office',
            'region',
            'tax_category_level_1',
            'tax_category_level_2',
            'tax_category_level_3',
            'tax_category_level_4',
            'tax_category_level_5',
            'tax_category_level_6',
            'value_type'
        ]) }} AS tax_revenue_id,
        *
    FROM renamed
),

final AS(
    SELECT *
    FROM added_surrogate_key
)

SELECT *
FROM final