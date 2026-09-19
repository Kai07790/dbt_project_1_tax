WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'local_tax_provincial') }}
),

renamed AS(
    SELECT
        SAFE_CAST(`연도` AS INT64) AS tax_year,
        `지역` AS region,
        `세목별1` AS tax_category_level_1,
        `세목별2` AS tax_category_level_2,
        SAFE_CAST(`세수액` AS INT64) * 1000 AS tax_amount
    FROM source
),

added_surrogate_key AS(
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'tax_year',
            'region',
            'tax_category_level_1',
            'tax_category_level_2'
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