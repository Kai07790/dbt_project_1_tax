import pandas as pd


# 1. 국세 데이터 처리
df_nat = pd.read_csv('raw_data/national_tax_raw.csv', encoding='utf-8', header=[0, 1, 2, 3])

df_nat_melted = df_nat.melt(
    id_vars=df_nat.columns[:6].tolist(), 
    var_name=['연도', '지방청', '지역', '금액 단위'], 
    value_name='세수액'
)

df_nat_melted.columns = [
    '세목별1',
    '세목별2',
    '세목별3',
    '세목별4',
    '세목별5',
    '세목별6',
    '연도',
    '지방청',
    '지역',
    '금액_단위',
    '세수액'
]

df_nat_melted.to_csv('processed_data/national_tax_processed.csv', index=False, encoding='utf-8')


# 2. 지방세 데이터 처리 (metro: 특별시,광역시 / provincial: 도 단위)

target_files = ['local_tax_metro', 'local_tax_provincial']

for file_name in target_files:
    input_path = f'raw_data/{file_name}_raw.csv'
    output_path = f'processed_data/{file_name}_processed.csv'
    df = pd.read_csv(input_path, encoding='utf-8', header=[0, 1])

    df_melted = df.melt(
        id_vars=df.columns[:2].tolist(),
        var_name=['연도', '지역'],
        value_name='세수액'
    )

    df_melted.columns = [
        '세목별1',
        '세목별2',
        '연도',
        '지역',
        '세수액'
        ]

    df_melted.to_csv(output_path, index=False, encoding='utf-8')


# 3. 인구 데이터 처리

df_pop = pd.read_csv('raw_data/population_raw.csv', encoding='utf-8', header=[0, 1])

df_pop_melted = df_pop.melt(
    id_vars=df_pop.columns[:2].tolist(),
    var_name=['연도', '지역'],
    value_name='인구수'
    )

df_pop_melted.columns = [
    '항목',
    '5세별',
    '연도',
    '지역',
    '인구수'
    ]

df_pop_melted.to_csv('processed_data/population_processed.csv', index=False, encoding='utf-8')