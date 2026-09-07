---
type: Reference
title: CEO interval cleaning code
description: Evidence excerpt from lib/create/intervals.do, CEO spell interval algebra and cleaning.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# CEO interval cleaning code

## Source

- Path: `lib/create/intervals.do`
- SHA-256: `869f2a7621c5f10357a644c0826bb5857b3838a8941eaab92f2978b5ad751d1d`
- Inspected: exact source slices below

## Excerpts

### Lines 1-11
```text
local T 2
local max_ceo_spells 12            // Must match lib/util/filter.do max_ceo_spells

use "input/manager-db-ceo-panel/ceo-panel.dta", clear

keep frame_id_numeric year person_id 
duplicates drop

drop if missing(frame_id_numeric, person_id, year)

do "lib/util/potholes.do"
```

### Lines 14-24
```text
collapse (firstnm) start_year (max) end_year = year, by(frame_id_numeric person_id spell)
tempfile clean_intervals
save "`clean_intervals'", replace
egen N = count(spell), by(frame_id_numeric)
drop spell

* single-ceo firms need not be touched
drop if N == 1

* limit to firms with not too many managers
drop if N > `max_ceo_spells'
```

### Lines 36-57
```text
* self-matches dropped and only of the pair is kept
drop if (interval_id_1 == interval_id_2) | (interval_id_1 > interval_id_2)

* we are using https://en.wikipedia.org/wiki/Allen%27s_interval_algebra
label define relation 1 "before" 2 "meets" 3 "overlaps" 4 "starts" 5 "during" 6 "finishes" 7 "equal" 8 "finished_by" 9 "contains" 10 "started_by" 11 "overlapped_by" 12 "met_by" 13 "after"
generate byte relation = .
replace relation = 1 if end_year_1 < start_year_2 
replace relation = 2 if end_year_1 == start_year_2
replace relation = 3 if end_year_1 > start_year_2 & end_year_1 < end_year_2 & start_year_1 < start_year_2
replace relation = 4 if start_year_1 == start_year_2 & end_year_1 < end_year_2
replace relation = 5 if start_year_1 > start_year_2 & end_year_1 < end_year_2
replace relation = 6 if end_year_1 == end_year_2 & start_year_1 > start_year_2
replace relation = 7 if start_year_1 == start_year_2 & end_year_1 == end_year_2
replace relation = 8 if end_year_1 == end_year_2 & start_year_1 < start_year_2
replace relation = 9 if start_year_1 < start_year_2 & end_year_1 > end_year_2
replace relation = 10 if start_year_1 == start_year_2 & end_year_1 > end_year_2
replace relation = 11 if end_year_1 > start_year_2 & end_year_1 < end_year_2 & start_year_1 > start_year_2
replace relation = 12 if end_year_1 == start_year_2
replace relation = 13 if start_year_1 > end_year_2

label values relation relation
tabulate relation, missing
```

### Lines 59-109
```text
/* interval cleaning: 
1. if there is a during, contains, starts, finishes, started_by, finished_by, the smaller interval is dropped if less than equal T years
2. if overlaps or overlapped_by, we truncate the earlier interval's end to coincide with the later interval's start if the overlap is less than equal T years
*/

* compute length of intervals
generate length_1 = end_year_1 - start_year_1 + 1
generate length_2 = end_year_2 - start_year_2 + 1

* 1. use inlist
generate byte drop_1 = inlist(relation, 4, 5, 6, 8, 9, 10) & length_1 <= `T'
generate byte drop_2 = inlist(relation, 4, 5, 6, 8, 9, 10) & length_2 <= `T'
* if both are shorter than T, we drop only the shorter
replace drop_1 = 0 if drop_1 == 1 & drop_2 == 1 & length_1 > length_2
replace drop_2 = 0 if drop_1 == 1 & drop_2 == 1 & length_1 < length_2

* 2. flag overlaps to use in #2 with an inlist and compute overlap length with cond()
generate overlap_length = cond(relation == 3, end_year_1 - start_year_2 + 1, end_year_2 - start_year_1 + 1) if inlist(relation, 3, 11)
* which to trance, what year to put in
generate byte truncate_1 = relation == 3 & overlap_length <= `T'
generate byte truncate_2 = relation == 11 & overlap_length <= `T'
generate truncate_year_1 = cond(truncate_1, start_year_2, .)
generate truncate_year_2 = cond(truncate_2, start_year_1, .)

* all other relations are kept intact. sine we only care about moditifcations, they can be dropped from data
drop if !drop_1 & !drop_2 & !truncate_1 & !truncate_2

* now execute all drops and truncations
replace end_year_1 = truncate_year_1 if truncate_1 == 1
replace end_year_2 = truncate_year_2 if truncate_2 == 1

keep person_id_? start_year_? end_year_? interval_id_? truncate_? drop_? frame_id_numeric
generate index = _n
reshape long person_id_ start_year_ end_year_ interval_id_ truncate_ drop_, i(index frame_id_numeric) j(j)
rename *_ *

* of each pair of intervals, exactly one should be modified, otherwise we have a problem
egen Nmod = total(drop | truncate), by(index)
assert Nmod == 1

keep if drop | truncate
keep frame_id_numeric person_id start_year end_year truncate drop
duplicates drop

merge 1:1 frame_id_numeric person_id start_year using "`clean_intervals'", keep(match using match_update match_conflict) update 
tabulate _merge

drop if drop == 1
drop _merge drop truncate

save "temp/intervals.dta", replace
```

## Notes

- Produces `temp/intervals.dta`: cleaned CEO tenure intervals at firm-person-spell level.
- The two-year threshold `T = 2` governs both drop and truncate decisions.
- Single-CEO firms are dropped before pairwise interval algebra (line 21`.
