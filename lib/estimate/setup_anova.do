args sample
confirm file "temp/placebo_`sample'.dta"

* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
global random_seed 2181            // Random seed for reproducibility
global cluster frame_id_numeric     // Clustering variable

* report package versions
which xt2treatments
* clustering requites xt2treatments 0.9 or higher
which estout
which reghdfe
which e2frame

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen


* the same firm may appear multipe times as control, repeat those observations
joinby frame_id_numeric using "temp/placebo_`sample'.dta"

* only do variance decomposition for first two spells
keep if inrange(ceo_spell, 1, 2) | placebo

* limit to relevant CEO spells
keep if inrange(year, window_start, window_end)

* for 2-ceo firms, only keep 1 of them, these are only placebo anyway
tabulate n_ceo
bysort fake_id year (person_id): generate keep = _n == 1
tabulate n_ceo keep
keep if keep == 1
drop keep
* bad naming, sorry!

* check balance
tabulate year placebo
tabulate change_year placebo

* reindex CEO spells, 1 is found, 2 is non-founder
egen first_spell = min(ceo_spell), by(fake_id)
replace ceo_spell = ceo_spell - first_spell + 1

* create fake CEO spells for placebo group
tabulate ceo_spell placebo
* should be 1 and 2 only
summarize ceo_spell if placebo == 0
local s1 = r(min)
local s2 = r(max)
assert `s1' == 1
assert `s2' == 2
replace ceo_spell = `s1' if placebo == 1 & year < change_year
replace ceo_spell = `s2' if placebo == 1 & year >= change_year
tabulate ceo_spell placebo

* CEO skill is also fake, computed from actual TFP
egen fake_manager_skill = mean(TFP), by(fake_id ceo_spell)
replace manager_skill = fake_manager_skill if placebo == 1
drop fake_manager_skill
