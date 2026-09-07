---
type: Reference
title: Balance sheet processing code
description: Evidence excerpt from lib/create/balance.do, the balance sheet cleaning script.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Balance sheet processing code

## Source

- Path: `lib/create/balance.do`
- SHA-256: `c00e484d35d50fe45e188910a837b59faf46ddc04a6b050d47b178572c41c07e`
- Inspected: exact source slices below

## Excerpts

### Lines 4-11
```text
local start_year 1992             // Start year for data inclusion
local end_year 2023               // End year for data inclusion

use "input/merleg-LTS-2023/balance/balance_sheet_80_22.dta", clear

keep if inrange(year, `start_year', `end_year')
drop if frame_id == "only_originalid"
generate long frame_id_numeric = real(substr(frame_id, 3, .)) if substr(frame_id, 1, 2) == "ft"
```

### Lines 33-54
```text
* Drop firm-years with missing core vars.
local core_vars sales employment tangible_assets materials personnel_expenses assets

local N_before = _N
generate byte core_missing = 0
foreach var of local core_vars {
    display "Missing `var': "
    count if missing(`var')
    replace core_missing = 1 if missing(`var')
}
count if core_missing == 1
display "Total firm-years with any missing core variable: " r(N) " out of `N_before'"

* find first year with complete core data for each firm
egen first_clean_year = min(cond(core_missing == 0, year, .)), by(frame_id_numeric)
count if year < first_clean_year
display "Firm-years before first clean year: " r(N)
count if core_missing == 1 & year >= first_clean_year
display "Firm-years with missing core after first clean year: " r(N)

drop if year < first_clean_year | core_missing == 1
display "Dropped " `N_before' - _N " firm-years, " _N " remaining"
```

### Lines 57-65
```text
mvencode sales export employment assets tangible_assets materials wagebill personnel_expenses intangible_assets state_owned foreign_owned, mv(0) override
replace employment = employment + 1
replace employment = int(employment)

* return on assets, but also defined, if L. is missing, assuming EBITDA increased assets
* this has to be done on the firm panel so that xtset is unambiguous
xtset frame_id_numeric year
generate EBITDA = sales - personnel_expenses - materials
generate capital = cond(missing(L.assets), assets - EBITDA, L.assets)
```

## Notes

- The script reads the raw Mrleg LTS balance sheet file and saves `temp/balance.dta` (line 68`.
- Employment is incremented by 1 before logarithm use (line 58`: `employment + 1`.
- `frame_id_numeric` is extracted from a string prefix `"ft"` (line 11`.
- The end year in the local is 2023, while several README/doc texts say 2022. This is a declared/intended parameter, not an observed run.
