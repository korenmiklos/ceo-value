---
type: Reference
title: Sample filter code
description: Evidence excerpt from lib/util/filter.do, final sample restrictions.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Sample filter code

## Source

- Path: `lib/util/filter.do`
- SHA-256: `8c3d2ddbc830806fb64f3cf17420f302b1487293902c20248c111beaacb4a3c8`
- Inspected: exact source slices below

## Excerpts

### Lines 7-13
```text
local full
local size1         employment <= 5
local size2         employment > 5 & employment <= 10
local size3         employment > 10 & employment <=25
local size4         employment > 25
local pre2000       year <= 2000
local post2000      year > 2000
```

### Lines 21-25
```text
local max_ceos_per_year 2         // Maximum number of CEOs allowed per firm per year
local max_ceo_spells 12            // Maximum CEO spell threshold
local min_firm_age 1              // Minimum firm age (drops age 0)
local excluded_sectors "9"     // Sector codes to exclude (finance)
local min_employment 3        // Minimum employment for analysis, cutoff values 2,3,5
```

### Lines 54-82
```text
drop if ceo_spell == 0

* drop if firm has ever more than specified number of CEOs in a year
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
egen firm_tag = tag(frame_id_numeric)
tabulate max_n_ceo if firm_tag, missing

drop if max_n_ceo > `max_ceos_per_year'
drop if max_ceo_spell > `max_ceo_spells'

* first year of firm is often incomplete, so we drop it
drop if firm_age < `min_firm_age'

* drop mining and finance sectors
tabulate sector if firm_tag
drop if inlist(sector, `excluded_sectors')

* drop firms with too few employees
summarize max_employment if firm_tag, detail
drop if max_employment < `min_employment'

* clean up
drop max_n_ceo firm_tag
drop if missing(lnR)
drop if missing(ROA)
drop if missing(lnL)
drop if missing(lnK)
drop if missing(lnRL)
drop if missing(export)
```

### Lines 87-88
```text
display "Keeping `sample' sample: ``sample''"
keep if ``sample''
```

## Notes

- The comment on line 25 says the employment cutoff values are "2,3,5" but the active parameter is `min_employment 3` (and `size1` uses employment <=`5`  a boundary mismatch worth noting).
- Sector code 9 (Finance) is excluded; the code comment block lists Hungarian legal form codes 1-23 for context.
