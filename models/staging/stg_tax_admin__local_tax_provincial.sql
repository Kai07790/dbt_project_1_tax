WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'local_tax_provincial') }}
),

renamed AS(
    SELECT
        `자치단체별1` AS region,
        SAFE_CAST(`연도` AS INT64) AS tax_year,
        `분류` AS tax_type,
        `세목` AS tax_name,
        SAFE_CAST(`세수액` AS INT64) AS tax_amount
    FROM source
)

SELECT *
FROM renamed