# 모델 설계

[README로 돌아가기](../README.md)

## 레이어별 역할

| 레이어 | 역할 | 저장 방식 |
|---|---|---|
| Python | 다중 헤더 CSV 읽기, wide → long 변환, 출력 컬럼 정리 | CSV |
| Raw | 전처리 CSV를 적재한 원천 테이블 | BigQuery Table |
| Staging | 타입·단위·명칭 정제, 원천 계층 보존 | View |
| Intermediate | 분석 세목 선정, 지역 병합, 공통 grain 집계 | View |
| Fact | 국세·지방세 통합 | Table |
| Reporting | 분석 목적별 집계와 재사용 지표 | Table |
| Analysis | 순위, 기간별 구성비 변화, 지역 집중도 비교 | 별도 실행 SQL |

현재 `profiles.yml`의 기본 dataset은 `tax_admin`입니다. `dbt_project.yml`의 schema 설정에 따라 Staging·Intermediate·Marts·Seed는 각각 `tax_admin_staging`, `tax_admin_intermediate`, `tax_admin_marts`, `tax_admin_seeds`에 생성됩니다. Raw는 source에 지정된 `tax_admin_raw`를 참조합니다.

## Staging과 Seed

| 모델 | Grain | 주요 처리 |
|---|---|---|
| `stg_tax_admin__national_tax` | `tax_year × regional_tax_office × region × tax_category_level_1~6` | 국세 단위를 원으로 통일하고, 세목 계층에서 구조적 `소계`를 제외한 실질 세목명 추출 |
| `stg_tax_admin__local_tax_metro` | `tax_year × region × tax_category_level_1 × tax_category_level_2` | 특별·광역시 지방세의 명칭·타입·단위 정제 |
| `stg_tax_admin__local_tax_provincial` | 위와 같음 | 도 단위 지방세의 명칭·타입·단위 정제 |
| `stg_tax_admin__population` | `population_year × region × gender × age` | 지역명·성별·연령구간·인구수 정제 |

국세의 `tax_category_level_1~6`은 실제로 6개 컬럼을 의미합니다. 경기 지역은 중부청과 인천청에 각각 존재하므로, Staging에서는 지방청도 행 식별에 필요합니다. 지방세는 동일 세목이 상위 분류 아래 반복될 수 있어 두 계층을 함께 보존합니다.

`region_mapping` Seed는 원천별 시·도 명칭을 표준 지역명으로 연결합니다. 동일 지역의 명칭 정리와 서로 다른 지역의 병합은 구분합니다. 지방세·인구의 충남과 세종 병합은 Intermediate에서 수행합니다.

구체적인 컬럼과 테스트 정의는 [Staging YAML](../models/staging/_stg_tax_admin.yml)을 기준으로 관리합니다.

## Intermediate

### 국세: `int_tax_admin__national_tax`

- `중부청–인천` 행을 제외합니다.
- `effective_tax_category_name`으로 13개 분석 세목을 선택합니다.
- 지방청 구분을 제거하고 `tax_year × region × tax_name`으로 합산합니다. 경기의 중부청·인천청 금액도 이 과정에서 통합됩니다.
- 출력은 `tax_year`, `region`, `tax_name`, `tax_amount`입니다.

### 지방세: `int_tax_admin__local_tax`

- 특별·광역시와 도 데이터를 `UNION ALL`로 통합합니다.
- `tax_category_level_2`를 `tax_name`으로 사용하고 도축세·도시계획세·과년도수입을 제외합니다.
- 충남·세종을 병합한 뒤 `tax_year × region × tax_name`으로 합산합니다.
- 국세 Intermediate와 동일한 4개 컬럼을 제공합니다.

### 인구: `int_tax_admin__population`

- 충남·세종을 병합하고 성별·연령별 인구를 합산합니다.
- `population_year × region`별 `population_count`를 제공합니다.
- 성별·연령별 상세 분석이 필요하면 Staging에서 별도 모델을 구성할 수 있습니다.

## Fact

`fct_tax_revenue`는 두 세수 Intermediate를 `UNION ALL`로 연결하고 `tax_type`에 국세·지방세를 표시합니다.

| 컬럼 | 의미 |
|---|---|
| `tax_year` | 징수실적 연도 |
| `region` | 충남·세종을 포함한 16개 분석 지역 |
| `tax_type` | 국세 / 지방세 |
| `tax_name` | 세목명 |
| `tax_amount` | 원 단위 세수액 |

현재 세목명이 두 세금 유형 사이에서 중복되지 않으므로 YAML의 유일성 검증 기준은 `tax_year × region × tax_name`입니다. `tax_type`은 분석을 위한 구분 컬럼으로 유지합니다. 향후 유형 간 동명 세목을 추가하면 식별 기준과 테스트를 함께 재검토해야 합니다.

## Reporting

### 연도별: `rpt_tax_revenue_by_year`

Grain: `tax_year`

| 컬럼 | 계산 |
|---|---|
| `tax_amount_national` | 국세 합계 |
| `tax_amount_local` | 지방세 합계 |
| `tax_amount_total` | 국세 + 지방세 |
| `tax_share_local` | 지방세 / 전체 세수 |
| `tax_share_local_yoy_pp` | 전년 대비 지방세 비중 차이 × 100 |

### 세목별: `rpt_tax_revenue_by_tax_name`

Grain: `tax_year × tax_name`. SQL의 집계·윈도 함수에는 `tax_type`도 명시합니다.

| 컬럼 | 계산 |
|---|---|
| `tax_amount` | 연도·유형·세목별 세수 합계 |
| `tax_share_in_type` | 세목 세수 / 동일 연도·유형의 전체 세수 |
| `tax_amount_yoy_change` | 당해 연도 세수 − 전년도 세수 |
| `tax_amount_yoy_change_rate` | 증감액 / 전년도 세수 |

첫 연도인 2020년의 전년 대비 지표는 `NULL`입니다. 순위는 Reporting 컬럼으로 저장하지 않고 Analysis SQL에서 계산합니다.

### 지역별: `rpt_tax_revenue_by_region`

Grain: `tax_year × region`

국세·지방세·취득세·지방소비세를 각각 집계한 뒤, 동일한 연도·지역 기준으로 인구 Intermediate를 `LEFT JOIN`합니다.

출력 컬럼은 `tax_year`, `region`, `region_type`, `population_count`, `tax_amount_national`, `tax_amount_local`, `tax_amount_acquisition`, `tax_amount_local_consumption`입니다. `region_type`은 서울·경기·인천을 수도권으로 분류합니다.

**지역별 모델은 금액·인구·지역 구분을 제공합니다. 수도권 비중과 인구 대비 격차는 Analysis SQL에서 계산합니다.** 세목별 Fact에 인구를 바로 조인하지 않아 인구의 중복 집계를 방지합니다.

## 질문별 Analysis SQL

| 파일 | 입력 | 처리 |
|---|---|---|
| [tax_name_revenue_rankings.sql](../analyses/tax_name_revenue_rankings.sql) | 세목별 Reporting | 세수 규모 및 증가·감소액 각각 상위 3위. `RANK`를 사용해 동순위를 포함 |
| [tax_name_share_trend.sql](../analyses/tax_name_share_trend.sql) | 세목별 Reporting | 2020~2024년 구성비와 양 끝 연도 간 차이(%p) |
| [tax_name_regional_concentration.sql](../analyses/tax_name_regional_concentration.sql) | 세수 Fact | 주요 6개 세목의 5년 누적 지역 비중, 상위 3개 지역 비중 합계 |
| [capital_area_tax_population_comparison.sql](../analyses/capital_area_tax_population_comparison.sql) | 지역별 Reporting | 국세·지방세·취득세·지방소비세의 수도권 비중, 인구 비중 및 격차 |

지역 집중도 분석은 `ROW_NUMBER`로 세목당 정확히 3개 지역을 선택하고, 금액 동률이면 지역명을 보조 정렬 기준으로 사용합니다. 수도권 비교는 세수 항목별로 인구를 집계하므로, 서로 다른 세수 항목의 결과 행을 합산해 전체 인구로 해석하면 안 됩니다.

## 설계 선택과 현재 계산 조건

- 별도 Dimension과 surrogate key는 도입하지 않았습니다. 현재 재사용할 차원 속성과 변경 이력이 제한적이므로 기존 지역·세목 키를 직접 사용합니다.
- 인구는 이미 연도·지역 단위로 집계되어 있어 별도 인구 Fact 없이 Intermediate를 참조합니다.
- 재사용하는 지표는 Reporting에, 특정 질문의 순위·피벗·집중도 계산은 Analysis에 둡니다.
- 현재 비율 계산은 이상치 발견을 위해 `SAFE_DIVIDE`가 아닌 `/` 연산자를 사용합니다. 새로운 기간·세목으로 범위를 확장할 때는 분모 0의 처리 기준과 테스트를 함께 정해야 합니다.
- `LAG`는 직전 행을 참조합니다. 현재의 연속된 2020~2024년 분석 범위를 넘어 확장할 경우 연도 누락 여부도 확인해야 합니다.
