---
type: Reference
title: Derived variable construction code
description: Evidence excerpt from lib/util/variables.do, derived variables definitions.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Derived variable construction code

## Source

- Path: `lib/util/variables.do`
- SHA-256: `4896fede21b1ee276c13643d826317bcff3a60675e98e02a859989b497902a3a`
- Inspected: exact source slices below

## Excerpts

### Lines 1-26
```text
generate byte exporter = export > 0 & !missing(export)

* log transformations
generate lnK = ln(tangible_assets)
generate lnA = ln(assets)
generate lnR = ln(sales)
generate lnEBITDA = ln(EBITDA)
generate lnL = ln(employment)
generate lnM = ln(materials)
generate lnWL = ln(wagebill) - lnL
generate lnKL = lnK - lnL
generate lnRL = lnR - lnL
generate lnMR = lnM - lnR
generate lnYL = ln(sales-materials) - lnL
generate exportshare = export / sales
replace exportshare = 0 if exportshare < 0
replace exportshare = 1 if exportshare > 1 & !missing(exportshare)
generate intangible_share = intangible_assets / (tangible_assets + intangible_assets)
replace intangible_share = 0 if intangible_share < 0 | missing(intangible_share)
replace intangible_share = 1 if intangible_share > 1
generate byte has_intangible = intangible_assets > 0
egen max_employment = max(employment), by(frame_id_numeric)
generate EBITDA_share = EBITDA / sales
replace EBITDA_share = 0 if EBITDA_share < 0
replace EBITDA_share = 1 if EBITDA_share > 1 & !missing(EBITDA_share)
generate ROA= EBITDA/(L.tangible_assets + tangible_assets) * 2
```

### Lines 28-29
```text
sum ROA, d
replace ROA = . if ROA < r(p1) | (ROA>r(p99) & !missing(ROA))
```

### Lines 35-41
```text
* ceo_spell = 0 denotes firm-years with no CEO
tabulate ceo_spell if firm_year_tag, missing
egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
tabulate max_ceo_spell if firm_tag, missing

egen last_year = max(year), by(frame_id_numeric)
generate byte exit = (year == last_year)
```

### Lines 46-64
```text
generate firm_age = year - foundyear
replace firm_age = 20 if firm_age > 20 & !missing(firm_age)
* use 3-year windows for cohort to increase cohort sizes
generate cohort = int(foundyear/3)*3
tabulate cohort, missing
* 1989 is divisible by 3
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing

* quadratics
foreach var in firm_age {
    generate `var'_sq = `var'^2
}

* variables fixed by firm, can be used for segmenting the analysis
egen byte early_exporter = max(exporter & (ceo_spell <= 1)), by(frame_id_numeric)
egen early_employment = max(cond(ceo_spell <= 1, employment, .)), by(frame_id_numeric)
generate max_size = cond(max_employment < 10, 1, 2)
generate early_size = cond(early_employment < 10, 1, 2)
```

## Notes

- ROA is EBITDA over average of current and lagged tangible assets, winsorized at p1/p99.
- Cohort bins are 3-year windows starting from  1989 (divisible by 3}.
