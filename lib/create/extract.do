*! version 1.0 2025-08-01
*! Extract manager value data for external analysis

* Standard setup
clear all

use "temp/manager_value.dta", clear
keep if !missing(component_id) & (component_id > 0)

* fixed effects are identified only up to a constant by connected component
* normalize mean to zero
* NOTE: this is only done for large-enough components, currently >= 30
egen MS_mean = mean(manager_skill), by(component_id)

* we are also shrinking towards component mean beceause of estimated noise (empirical Bayes)
* use 0.25 from 62784d39de446d311568db51fedc3326e3db7212
replace manager_skill = 0.25 * (manager_skill - MS_mean) if !missing(MS_mean)
drop MS_mean

* babyboom measures manager skills not in TFP, but as a fixed input
replace manager_skill = manager_skill / chi
summarize manager_skill, detail

generate year = 2015
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match)
keep if n_ceo == 1

* sales in million HUF
replace sales = sales/1e3
generate size = sales
summarize manager_skill if founder & size <= 50, detail
scalar low_skill = r(mean)
replace manager_skill = manager_skill - low_skill
recode size min/50 = 0 50/100 = 50 100/200 = 100 200/500 = 200 500/1000 = 500 1000/max = 1000

generate EBITDA_share = EBITDA / sales / 1e3
summarize EBITDA_share, detail
replace EBITDA_share = 0 if EBITDA_share < 0

tabulate size founder
table size founder, stat(mean manager_skill)
table size founder, stat(mean EBITDA_share)
table size founder, stat(mean sales)

collapse (count) n = manager_skill (mean) manager_skill EBITDA_share sales, by(size founder)
generate EBITDA = EBITDA_share * sales
generate manager_value = manager_skill * EBITDA_share * sales
foreach X in manager_skill EBITDA_share {
	replace `X' = round(`X'*1000)/1000
}
foreach X in sales manager_value EBITDA {
	replace `X' = round(`X'*10)/10
}
* suppose small founder have value z = EBITDA
summarize EBITDA if founder & size == 0
replace manager_value = manager_value + r(mean)

reshape wide n manager_skill EBITDA_share EBITDA sales manager_value, i(size) j(founder)
order size n1 n0 EBITDA1 EBITDA0 manager_value1 manager_value0

export delimited "output/extract/value_bins.csv", replace

clear all
use "temp/surplus.dta", clear

* Identify managers who started in 2015
egen first_year = min(year), by(frame_id_numeric ceo_spell)
egen ceo_spell_in_2015 = mean(cond(year == 2015 & first_year == 2015, ceo_spell, .)), by(frame_id_numeric)

* no change in 2015
drop if missing(ceo_spell_in_2015)
* this is the start, not a change
drop if ceo_spell_in_2015 == 1

* keep the 2015 starter and the previous CEO
keep if inrange(ceo_spell, ceo_spell_in_2015 - 1, ceo_spell_in_2015)

generate byte before = year < 2015
tabulate ceo_spell before, missing

* how many managers per firm before and after 2015?
egen fmtag = tag(frame_id_numeric person_id before)
egen n_managers = total(fmtag), by(frame_id_numeric before)
tabulate n_managers before, missing

* Keep only firms with exactly one manager before and after 2015
egen max_n_managers = max(n_managers), by(frame_id_numeric)
keep if max_n_managers == 1
drop max_n_managers

* now ready to compute statistics
collapse (mean) TFP (firstnm) person_id chi (count) T_spell = TFP, by(frame_id_numeric before)
generate str when = cond(before, "_before", "_after")
drop before
reshape wide TFP person_id T_spell, i(frame_id_numeric) j(when) string
* verify that managers are different
count if person_id_before == person_id_after
drop if person_id_before == person_id_after

* only keep firms with same two managers in 2013-2017 period
drop if T_spell_before < 2 | T_spell_after < 3

keep if !missing(TFP_before, TFP_after)
generate surplus_change = (TFP_after - TFP_before) / chi
keep frame_id_numeric surplus_change chi

* convert this to forints
preserve
	use "temp/analysis-sample.dta", clear
	keep frame_id_numeric year EBITDA sales sector teaor08_2d

	keep if inrange(year, 2012, 2013)
	collapse (mean) EBITDA sales (firstnm) sector teaor08_2d, by(frame_id_numeric)

	tempfile EBITDA
	save `EBITDA', replace
restore

merge 1:1 frame_id_numeric using `EBITDA', keep(match) nogen
rename EBITDA EBITDA1
generate EBITDA2 = sales * chi

correlate EBITDA?
summarize EBITDA1, detail
count if EBITDA1 < 0 
* actual EBITDA is often negative, but inferring from sales is very similar

keep frame_id_numeric surplus_change sales EBITDA1 EBITDA2 
save "output/extract/manager_changes_2015.dta", replace

display "Extract 2 saved: Firms with manager changes in 2015"

* =============================================================================
* Extract 3: Connected component managers
* =============================================================================

* Get first year from CEO panel
use "input/ceo-panel/ceo-panel.dta", clear
collapse (min) entry_year = year (firstnm) birth_year hungarian_name male, by(person_id)
* we may not observe true entry, assume CEOs were at least 18 when they started
replace entry_year = birth_year + 18 if entry_year < birth_year + 18 & !missing(birth_year)
* we don't know gender if non-Hungarian, assume male
replace male = 1 if missing(male)

tempfile first_year
save `first_year'

use "temp/surplus.dta", clear
collapse (firstnm) manager_skill, by(person_id)
keep if !missing(manager_skill)

merge 1:1 person_id using `first_year', keep(match) nogen
generate ceo_age = year - birth_year if !missing(birth_year)
replace ceo_age = 18 if ceo_age < 18
replace ceo_age = 90 if ceo_age > 90 & !missing(ceo_age)

compress
save "output/extract/connected_managers.dta", replace

display "Extract 3 saved: Connected component managers with characteristics"
