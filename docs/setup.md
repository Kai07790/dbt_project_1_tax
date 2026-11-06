# 실행 가이드

[README로 돌아가기](../README.md)

## 사전 준비

Python·pandas, dbt Core 및 BigQuery 어댑터가 설치된 환경과 BigQuery 프로젝트가 필요합니다. 저장소의 실행 환경에 맞는 패키지 버전을 사용하세요. 현재 저장소 루트에는 Python 패키지 버전을 고정한 requirements 파일이 없습니다.

아래 명령은 프로젝트 루트에서 실행합니다. 전체 과정은 원본 CSV 준비 → Python 전처리 → BigQuery Raw 적재 → dbt 빌드 → 분석 SQL 실행 순서입니다. Raw 적재는 현재 저장소의 Python 스크립트에 포함되어 있지 않습니다.

## 1. 원본 CSV와 출력 폴더 준비

KOSIS에서 내려받은 파일을 다음 경로에 둡니다. 통계표와 분석 범위는 [데이터 범위](data_scope.md)를 참고하세요.

| 입력 | 출력 |
|---|---|
| `raw_data/national_tax_raw.csv` | `processed_data/national_tax_processed.csv` |
| `raw_data/local_tax_metro_raw.csv` | `processed_data/local_tax_metro_processed.csv` |
| `raw_data/local_tax_provincial_raw.csv` | `processed_data/local_tax_provincial_processed.csv` |
| `raw_data/population_raw.csv` | `processed_data/population_processed.csv` |

`raw_data`와 `processed_data` 폴더를 먼저 생성합니다. 스크립트는 국세 CSV의 4줄 헤더와 지방세·인구 CSV의 2줄 헤더를 전제로 하므로 다운로드 형식이 다르면 입력 구조를 맞춰야 합니다.

```bash
python scripts/preprocess.py
```

스크립트는 다중 헤더를 읽어 `melt`로 long 형태로 변환하고 컬럼명을 지정합니다. 세목 선정·지역 병합은 dbt에서 수행합니다.

## 2. BigQuery Raw 적재

전처리 결과를 BigQuery의 `tax_admin_raw` dataset에 다음 테이블명으로 적재합니다.

| 전처리 파일 | Raw 테이블 |
|---|---|
| `national_tax_processed.csv` | `national_tax` |
| `local_tax_metro_processed.csv` | `local_tax_metro` |
| `local_tax_provincial_processed.csv` | `local_tax_provincial` |
| `population_processed.csv` | `population` |

헤더를 컬럼명으로 사용하고 [source 정의](../models/staging/_src_tax_admin.yml) 및 Staging SQL의 참조 컬럼과 일치하는지 확인합니다. Raw와 생성할 dataset의 위치도 일치시킵니다.

## 3. 프로젝트와 인증 설정

현재 저장소는 루트의 `profiles.yml`을 사용하며, BigQuery service-account 인증과 `./bigquery_key.json` 경로를 참조합니다. 본인의 인증 파일과 실행 환경에 맞게 설정합니다. 인증 키는 Git에 추가하지 않습니다.

다른 프로젝트에서 실행하려면 두 설정을 모두 변경해야 합니다.

- `profiles.yml`: 출력 대상 `project`, 기본 `dataset`, `keyfile` 등
- `models/staging/_src_tax_admin.yml`: 원천 테이블을 읽을 `database`, `schema`

```bash
dbt debug --profiles-dir .
dbt deps --profiles-dir .
dbt build --profiles-dir .
```

선택 조건 없이 실행하는 `dbt build`에는 Seed도 포함되므로 `dbt seed`를 별도로 선행할 필요는 없습니다. Seed만 갱신할 때는 `dbt seed --profiles-dir .`를 사용합니다.

## 4. 분석 SQL 실행

`analyses/`의 SQL은 `dbt build`로 실행되지 않습니다. `ref()`를 실제 BigQuery 테이블 경로로 변환하기 위해 컴파일합니다.

```bash
dbt compile --profiles-dir .
```

컴파일된 파일은 `target/compiled/dbt_project_1_tax/analyses/`에서 확인합니다. 해당 SQL을 BigQuery 쿼리 편집기에 붙여 넣고 실행합니다.

| 질문 | 실행 파일 |
|---|---|
| Q1 | `rpt_tax_revenue_by_year` 테이블 조회 |
| Q2-1 | `tax_name_revenue_rankings.sql` |
| Q2-2 | `tax_name_share_trend.sql` |
| Q3-1 | `tax_name_regional_concentration.sql` |
| Q3-2 | `capital_area_tax_population_comparison.sql` |

예를 들어 기본 프로젝트 설정의 Q1 결과는 다음처럼 조회합니다.

```sql
SELECT *
FROM `dbt-project-1-tax.tax_admin_marts.rpt_tax_revenue_by_year`
ORDER BY tax_year;
```

비율은 원본 결과에서 `1 = 100%`인 값으로 반환됩니다. `%`로 표시하려면 100을 곱합니다. 컬럼명이 `_pp`로 끝나는 비중 차이는 이미 %p 단위이므로 다시 100을 곱하지 않습니다.

## 재현 범위

저장소는 전처리와 dbt 변환·테스트 로직을 제공합니다. 원본 CSV 확보와 BigQuery 적재는 별도로 수행해야 하며, 현재 단계에서 예약 실행·자동 수집까지 포함한 운영 파이프라인을 제공하지는 않습니다.
