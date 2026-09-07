---
type: Data source
title: Mérleg LTS - Hungarian Balance Sheet Data
description: Proprietary administrative balance sheet data for essentially all Hungarian firms, 1980-2022, distributed by HUN-REN KRTK, originally published by Opten Zrt.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: readme
    resource: ../references/readme.md
    locator: Lines  18-44 (data availability table)
  - id: balance_code
    resource: ../references/code/balance_do.md
    locator: Lines  4-11 (years and firm ID)
  - id: input_listing
    resource: ../build/2026-09-07/record.md
    locator: Input inventory (observed files)
relations: []
---

# Mérleg LTS - Hungarian Balance Sheet Data

## Origin and access

The Mérleg LTS dataset contains financial information for essentially all Hungarian firms required to file annual reports. It is distributed by HUN-REN KRTK, originally published by Opten Zrt. Data are proprietary and cannot be made public; commercial access via opten.hu, academic replication access via KRTK Adatbank.



Raw files in this checkout:

- `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` - the file consumed by the pipeline.
- `input/merleg-LTS-2023/machine/...` - machine-readable balance sheet variant - not consumed by traced scripts. 
- `input/merleg-LTS-2023/address/...` - address/site/branch panels - not consumed by traced scripts. 

## Coverage and contents (declared)

- Years the balance file covers 1980-2022; the cleaning script restricts the analysis to 1992-2023.
- Contains firm identifiers, financial variables sales, export, employment, assets, tangible assets, materials, wagebill, personnel expenses, intangible assets; ownership flags state, foreign; industry codes teaor08_2d, teaor08_1d.



## Use in pipeline

Consumed by [balance.do](../dataset/balance_clean.md) - the first pipeline step extracts numeric firm IDs from the `"ft"` string prefix and builds `temp/balance.dta`.



No row counts were read from the raw file in this build (binary .dta was not inspected); coverage numbers in manuscripts remain declared, not observed.





[^readme]: README data availability statements - see [README](../references/readme.md)
[^input_listing]: Build record input inventory - see [build record](../build/2026-09-07/record.md)
[^balance_code]: Balance sheet processing code excerpt - see [balance.do](../references/code/balance_do.md)
