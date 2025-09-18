clear all
tempfile cohortsfile
save `cohortsfile', replace emptyok

local TARGET_N_CONTROL 50
local SEED 1391

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen keepusing(foundyear)

generate cohort = foundyear
tabulate cohort, missing
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing
collapse (min) window_start1 = year (max) window_end1 = year (min) cohort, by(frame_id_numeric ceo_spell)

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
        count`'
        joinby cohort using "temp/treatment_groups.dta"
        count
        * only keep controls that have weakly larger spell windows than the event window
        keep if window_start1 <= window_start & window_end1 >= window_end
        count
        keep frame_id_numeric ceo_spell cohort window_start window_end n_treated* N_TREATED

        * sample control firms, we have way too many
        egen n_control = total(1), by(cohort window_start window_end)
        summarize n_control, detail
        generate p = cond(n_control > `TARGET_N_CONTROL', `TARGET_N_CONTROL' / n_control, 1)
        keep if uniform() < p

        drop n_control p
        egen n_control = total(1), by(cohort window_start window_end)
        generate weight = n_treated / n_control

        * now create placebo times for CEO arrival
        generate byte t0 = .
        unab treatmens : n_treated?  
        local T : word count `treatmens'
        forvalues t = 1/`T' {
            replace t0 = `t' if missing(t0) & uniform() < n_treated`t' / n_treated
            replace n_treated = n_treated - n_treated`t'
        }
        tabulate t0, missing
        assert !missing(t0)

        generate change_year = window_start + t0
        drop t0

        list in 1/5
        append using `cohortsfile'
        save `cohortsfile', replace emptyok
    restore
}

use `cohortsfile', clear
egen tg_tag = tag(cohort window_start window_end)
summarize n_treated if tg_tag, detail
summarize n_control if tg_tag, detail

keep frame_id_numeric ceo_spell cohort window_start window_end change_year weight N_TREATED
* the same frame_id_numeric may appear multiple times
egen fake_id = group(frame_id_numeric ceo_spell window_start window_end change_year)
* make sure no overlap with fake_ids of treated firms
summarize fake_id
assert r(min) == 1
replace fake_id = fake_id + N_TREATED
drop N_TREATED

save "temp/placebo.dta", replace
