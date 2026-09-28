WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'local_tax_provincial') }}
),

region_mapping AS(
    SELECT *
    FROM {{ ref('region_mapping') }}
),

renamed AS(
    SELECT
        SAFE_CAST(s.`연도` AS INT64) AS tax_year,
        r.standard_region AS region,
        s.`세목별1` AS tax_category_level_1,
        s.`세목별2` AS tax_category_level_2,
        SAFE_CAST(s.`세수액` AS INT64) * 1000 AS tax_amount
    FROM source AS s 
    LEFT JOIN region_mapping AS r
        ON s.`지역` = r.raw_region
    WHERE s.`세목별2` != '소계'
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