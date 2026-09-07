---
type: Reference
title: CEO panel construction code
description: Evidence excerpt from lib/create/ceo-panel.do, constructing the firm-year CEO panel.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# CEO panel construction code

## Source

- Path: `lib/create/ceo-panel.do`
- SHA-256: `181003a2c1ad038a9714eff757b1034cc39fa538ad66227c408da9670d4a47d6`
- Inspected: exact source slices below

## Excerpts

### Lines 1-10
```text
use "temp/intervals.dta", clear

generate T = end_year - start_year + 1
tabulate T, missing
expand T

bysort frame_id_numeric person_id spell: generate year = start_year + _n -1

merge m:1 frame_id_numeric person_id using "temp/manager-firm-facts.dta", keep(match) nogen
merge m:1 person_id using "temp/manager-facts.dta", keep(match) nogen
```

### Lines 17-25
```text
collapse (count) n_ceo = person_id (max) has_expat_ceo = foreign_name has_founder = founder (max) someone_enters someone_exits (sum) n_ceo_male = male, by(frame_id_numeric year)

xtset frame_id_numeric year
generate byte someone_exited = L.someone_exits == 1

bysort frame_id_numeric (year): generate byte ceo_spell = sum(someone_enters | someone_exited)

keep frame_id_numeric year ceo_spell n_ceo has_expat_ceo has_founder n_ceo_male
save "temp/ceo-panel.dta", replace
```

## Notes

- Merges manager-firm facts (`temp/manager-firm-facts.dta`) and manager-level facts (`temp/manager-facts.dta`) before collapsing (lines 9-10}.
- `ceo_spell` counts CEO spells by cumulative entry/exit indicators; 0 denotes firm-years with no CEO (per variables.do comment}ets.
