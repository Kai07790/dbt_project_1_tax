WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'population') }}
),

renamed AS(
    SELECT
        `행정구역별_동읍면` AS region,
        `항목` AS gender,
        SAFE_CAST(`연도` AS INT64) AS population_year,
        `연령` AS age,
        SAFE_CAST(`인구수` AS INT64) AS population_count
    FROM source
)

SELECT *
FROM renamed