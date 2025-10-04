args sample
confirm existence `sample'

******************************
* ACCEPTED VALUES FOR sample *
******************************
local full         1
local fnd2fnd      founder1 == 1 & founder2 == 1 
local fnd2non      founder1 == 1 & founder2 == 0
local fnd2non12    founder1 == 1 & founder2 == 0 & ceo_spell1 == 1 & ceo_spell2 == 2
local non2fnd      founder1 == 0 & founder2 == 1
local non2non      founder1 == 0 & founder2 == 0
local post2004     window_start >= 2004

assert inlist("`sample'", "full", "fnd2fnd", "fnd2non", "non2fnd", "non2non", "post2004", "fnd2non12")

clear all
tempfile cohortsfile
save `cohortsfile', replace emptyok

local TARGET_N_CONTROL 10
local SEED 1391
global min_obs_threshold 1         // Minimum observations before/after
global min_T 1                     // Minimum observations to estimate fixed effects
global max_n_ceo 1                // Maximum number of CEOs per firm for analysis
global exact_match_on cohort sector // Variables to exactly match on for placebo

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen

* keep single-ceo firms
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate n_ceo max_n_ceo, missing
keep if max_n_ceo <= ${max_n_ceo}

* limit sample to clean changes  
keep if ceo_spell <= max_ceo_spell
keep if !missing(TFP)

tabulate ceo_spell

generate cohort = foundyear
tabulate cohort, missing
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing

* for some reason, there is 1 duplicate in cohort
egen min_cohort = min(cohort), by(frame_id_numeric)
replace cohort = min_cohort if cohort != min_cohort
drop min_cohort

* refactor to collapse
collapse (mean) MS = manager_skill (count) T = TFP (max) founder owner (min) change_year = year (max) window_end = year (firstnm) $exact_match_on, by(frame_id_numeric ceo_spell)

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

reshape wide MS T founder owner change_year window_end ceo_spell, i(frame_id_numeric spell_id) j(index)
rename change_year2 change_year

generate window_start = change_year1
generate window_end = window_end2
* need to sort on skill
drop if missing(MS1, MS2)
drop if ceo_spell1 != ceo_spell2 - 1

*********************
* LIMIT SAMPLE HERE *
*********************
display "Keeping `sample' sample: ``sample''"
keep if ``sample''

rename ceo_spell1 ceo_spell

collapse (min) window_start ceo_spell (max) window_end (firstnm) $exact_match_on change_year, by(frame_id_numeric spell_id)

* frame_id_numeric will stop being unique once we add placebo
egen fake_id = group(frame_id_numeric ceo_spell)
summarize fake_id
scalar N_TREATED = r(max)
generate byte placebo = 0
generate float weight = 1
compress

tempfile treated_firms
save "`treated_firms'", replace

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
scalar list

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen keepusing(foundyear)

generate cohort = foundyear
tabulate cohort, missing
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing
collapse (min) window_start1 = year (max) window_end1 = year (min) $exact_match_on, by(frame_id_numeric ceo_spell)

* we need at least T = 2 to have a before and after period
drop if window_end1 == window_start1

compress
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
}

use `cohortsfile', clear
egen tg_tag = tag($exact_match_on window_start window_end)
summarize N_treated if tg_tag, detail
summarize n_control if tg_tag, detail

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

save "temp/placebo_`sample'.dta", replace
