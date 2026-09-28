WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'population') }}
),

region_mapping AS(
    SELECT *
    FROM {{ ref('region_mapping') }}
),

renamed AS(
    SELECT
        SAFE_CAST(s.`연도` AS INT64) AS population_year,
        r.standard_region AS region,
        CASE
            WHEN s.`항목` = '남자인구수 (명)' THEN '남'
            WHEN s.`항목` = '여자인구수 (명)' THEN '여'
            ELSE NULL
        END AS gender,
        REPLACE(s.`5세별`, ' ', '') AS age,
        SAFE_CAST(s.`인구수` AS INT64) AS population_count
    FROM source AS s
    LEFT JOIN region_mapping AS r
        ON s.`지역` = r.raw_region
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