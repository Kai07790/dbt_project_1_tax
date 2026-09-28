WITH source AS(
    SELECT *
    FROM {{ source('tax_admin_raw', 'national_tax') }}
),

renamed AS(
    SELECT
        SAFE_CAST(`연도` AS INT64) AS tax_year,
        `지방청` AS regional_tax_office,
        -- 서울청의 소계 데이터는 단일 지역인 '서울'로 통일하여 취급
        CASE
            WHEN `지방청` = '서울청' AND `지역` = '소계' THEN '서울'
            ELSE `지역`
        END AS region,
        `세목별1` AS tax_category_level_1,
        `세목별2` AS tax_category_level_2,
        `세목별3` AS tax_category_level_3,
        `세목별4` AS tax_category_level_4,
        `세목별5` AS tax_category_level_5,
        `세목별6` AS tax_category_level_6,
        -- 하위 세목부터 역순으로 탐색하여 '소계'가 아닌 가장 구체적인 세목명을 추출
        COALESCE(
            NULLIF(`세목별6`, '소계'),
            NULLIF(`세목별5`, '소계'),
            NULLIF(`세목별4`, '소계'),
            NULLIF(`세목별3`, '소계'),
            NULLIF(`세목별2`, '소계'),
            `세목별1`
        ) AS effective_tax_category_name,
        SAFE_CAST(SAFE_CAST(`세수액` AS FLOAT64) * 1000000 AS INT64) AS tax_amount
    FROM source
    -- 일반 지역 및 서울청 소계 데이터만 유지하고, 타 지방청 소계(합계 성격) 및 지역 미상 더미 데이터(수입분내국세 등)는 파이프라인에서 제외
    WHERE
        `지역` != '소계'
        OR (`지방청` = '서울청' AND `지역` = '소계')
),

added_surrogate_key AS(
    -- 레코드 단위의 고유 식별자 생성
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
            'tax_category_level_6'
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