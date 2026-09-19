WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'population') }}
),

renamed AS(
    SELECT
        SAFE_CAST(`연도` AS INT64) AS population_year,
        `지역` AS region,
        `항목` AS gender,
        `5세별` AS age,
        SAFE_CAST(`인구수` AS INT64) AS population_count
    FROM source
),

added_surrogate_key AS(
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'population_year',
            'region',
            'gender',
            'age'
        ]) }} AS population_id,
        *
    FROM renamed
),

final AS(
    SELECT *
    FROM added_surrogate_key
)

SELECT *
FROM final