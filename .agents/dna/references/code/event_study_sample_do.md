---
type: Reference
title: Placebo event study sample construction code
description: Evidence excerpt from lib/create/event_study_sample.do, placebo CEO transition construction.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Placebo event study sample construction code

## Source

- Path: `lib/create/event_study_sample.do`
- SHA-256: `96de0c99a8e1545f402e88fc8fca35d844a7a01737774a348b82fc8523035016`
- Inspected: exact source slices below

## Excerpts

### Lines 1-17
```text
args variation sample
confirm existence `sample'
confirm existence `variation'
******************************
* ACCEPTED VALUES FOR sample *
******************************
local full          1
local fnd2non       has_founder1 == 1 & has_founder2 == 0
local non2non       has_founder1 == 0 & has_founder2 == 0
local small         max_size == 1
local large         max_size == 2
local one2one       n_ceo1 == 1 & n_ceo2 == 1
local twos          n_ceo1 == 2 | n_ceo2 == 2
local gap           (n_ceo1 == 1 & n_ceo2 == 1) & (age_diff > 10)
local nogap         (n_ceo1 == 1 & n_ceo2 == 1) & (age_diff <= 10)
local gender        n_ceo_male1 != n_ceo_male2
local nogender      n_ceo_male1 == n_ceo_male2
```

### Lines 27-34
```text
local TARGET_N_CONTROL 10
local SEED 1391
global min_obs_threshold 1         // Minimum observations before/after
global min_T 1                     // Minimum observations to estimate fixed effects
* we can also compute our analysis for spells with n_ceo > 1
global max_n_ceo 2                // Maximum number of CEOs per firm for analysis
global exact_match_on cohort sector max_size  // Variables to exactly match on for placebo
global fixed_effect ROA
```

### Lines 36-55
```text
use "temp/`variation'-analysis-sample.dta", clear

* person_id lives in intervals.dta, not in the firm-year panel
preserve
use "temp/intervals.dta", clear
generate T = end_year - start_year + 1
expand T
bysort frame_id_numeric person_id spell: generate year = start_year + _n - 1
keep frame_id_numeric person_id year
duplicates drop
tempfile ceo_person_year
save "`ceo_person_year'", replace
restore

joinby frame_id_numeric year using "`ceo_person_year'"

merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen
merge m:1 person_id using "temp/manager-facts.dta", keep(master match) nogen

* keep single-ceo firms
```

### Lines 75-111
```text
collapse (mean) MS = manager_skill (count) T = ${fixed_effect} (min) change_year = year ceo_age (max) window_end = year n_ceo has_founder (firstnm) $exact_match_on n_ceo_male, by(frame_id_numeric ceo_spell)

drop if missing(MS)
drop if T < ${min_T}

xtset frame_id_numeric ceo_spell
* drop if spells are not consecutive. this also excludes single-spell firms
tabulate ceo_spell
drop if missing(L.ceo_spell) & missing(F.ceo_spell)
tabulate ceo_spell

* intermediate spells have to be doubled so that before and after are both saved
egen first_spell = min(ceo_spell), by(frame_id_numeric)
egen last_spell = max(ceo_spell), by(frame_id_numeric)
generate duplicate = cond(ceo_spell > first_spell & ceo_spell < last_spell, 2, 1)
expand duplicate

bysort frame_id_numeric ceo_spell: generate index = _n
sort frame_id_numeric ceo_spell index
generate byte new_spell = ceo_spell[_n-1] == ceo_spell & frame_id_numeric[_n-1] == frame_id_numeric
bysort frame_id_numeric (ceo_spell index): generate byte spell_id = sum(new_spell)

drop first_spell last_spell duplicate index new_spell
bysort frame_id_numeric spell_id (ceo_spell): generate index = _n

reshape wide MS T change_year window_end ceo_spell n_ceo has_founder ceo_age n_ceo_male, i(frame_id_numeric spell_id) j(index)
rename change_year2 change_year

generate window_start = change_year1
generate window_end = window_end2
* need to sort on skill
drop if missing(MS1, MS2)
drop if ceo_spell1 != ceo_spell2 - 1
gen age_diff = ceo_age1 - ceo_age2
replace age_diff = ceo_age2-ceo_age1 if age_diff<0
su age_diff, det
*********************
```

### Lines 132-147
```text
generate t0 = change_year - window_start

collapse (count) n_treated = frame_id_numeric, by($exact_match_on window_start window_end t0)
* we will create random CEO changes with the same t0 distribution
reshape wide n_treated, i($exact_match_on window_start window_end) j(t0)
mvencode n_treated*, mv(0)
* bugfix: t0 may be two digits
egen byte N_treated = rowtotal(n_treated*)
compress

tempfile treated_groups
save "`treated_groups'", replace

summarize N_treated, meanonly
scalar MEAN = r(mean)
scalar MULTIPLE = `TARGET_N_CONTROL' / MEAN
```

### Lines 159-206
```text
set seed `SEED'

* to save memory, perform joinbys year by year
levelsof cohort, local(cohorts)
foreach cohort of local cohorts {
    display "Processing cohort `cohort'"
    preserve
        keep if cohort == `cohort'
        count
        joinby $exact_match_on using "`treated_groups'"
        count
        * only keep controls that have weakly larger spell windows than the event window
        keep if window_start1 <= window_start & window_end1 >= window_end
        count
        keep frame_id_numeric ceo_spell $exact_match_on window_start window_end N_treated n_treated*

        * sample control firms, we have way too many
        egen n_control = total(1), by($exact_match_on window_start window_end)
        summarize n_control, detail
        generate p = MULTIPLE * N_treated / n_control
        summarize p, detail
        keep if uniform() < p

        drop n_control p
        egen n_control = total(1), by($exact_match_on window_start window_end)
        generate weight = N_treated / n_control

        * now create placebo times for CEO arrival
        generate byte t0 = .
        * bugfix: treatment time may be two digits
        unab treatmens : n_treated*
        local T : word count `treatmens'
        generate p = .
        forvalues t = 1/`T' {
            replace p = cond(missing(t0), n_treated`t' / N_treated, 0)
            replace t0 = `t' if missing(t0) & uniform() <= p
            replace N_treated = N_treated - n_treated`t'
        }
        tabulate t0, missing
        assert !missing(t0)

        generate change_year = window_start + t0
        drop t0

        list frame_id_numeric ceo_spell change_year N_treated n_control weight in 1/5
        append using `cohortsfile'
        save `cohortsfile', replace emptyok
    restore
```

### Lines 214-247
```text
keep frame_id_numeric ceo_spell $exact_match_on window_start window_end change_year weight
* the same frame_id_numeric may appear multiple times
egen fake_id = group(frame_id_numeric ceo_spell window_start window_end change_year)
* make sure no overlap with fake_ids of treated firms
summarize fake_id
assert r(min) == 1
replace fake_id = fake_id + N_TREATED

generate byte placebo = 1

* because weight has already been used in samplign, sampling weight should not vary too much
summarize weight, detail

* add actuallly treated firms
append using "`treated_firms'"

* check balance
tabulate placebo
tabulate placebo [iw = weight]

tabulate change_year placebo

generate T1 = change_year - window_start
generate T2 = window_end - change_year + 1

tabulate T1 placebo
tabulate T2 placebo

local vars fake_id placebo frame_id_numeric window_start change_year ceo_spell window_end weight
keep `vars'
order `vars'
compress

save "temp/`variation'_placebo_`sample'.dta", replace
```

## Notes

- Current script requires two args (`variation sample`) and writes `temp/{variation}_placebo_{sample}.dta`.
- The observed `event_study_sample.log` run was `do lib/create/event_study_sample.do full`  a one-arg call against an older script version, producing `temp/placebo_full.dta` (variation-less naming.time The current variation-named outputs do not exist in the current `temp/` listing.
- Matching strata (`cohort sector max_size`) plus window bounds are used to sample up to 10:1 control-to-treated ratio with seed 1391.
