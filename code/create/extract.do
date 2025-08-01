*! version 1.0 2025-08-01
*! Extract manager value data for external analysis

* Standard setup
clear all
* Load manager value data with firm fixed effects
use "temp/manager_value.dta", clear

* =============================================================================
* Extract 1: Year 2022 - firm FE and manager value
* =============================================================================

keep if year == 2022
keep frame_id_numeric firm_fixed_effect manager_skill
compress
save "output/extract/2022_values.dta", replace

display "Extract 1 saved: 2022 firm FE and manager values"

* =============================================================================
* Extract 2: Manager changes in 2015
* =============================================================================

use "temp/surplus.dta", clear
keep if inrange(year, 2012, 2017)

* Identify managers who started in 2015
egen first_year = min(year), by(frame_id_numeric ceo_spell)
egen has_2015_change = max(year == 2015 & first_year == 2015), by(frame_id_numeric)
keep if has_2015_change == 1
drop has_2015_change first_year

* switching years can be noisy
drop if inrange(year, 2014, 2015)
generate byte before = year < 2015

* how many managers per firm before and after 2015?
egen fmtag = tag(frame_id_numeric person_id before)
egen n_managers = total(fmtag), by(frame_id_numeric before)
tabulate n_managers before, missing

* Keep only firms with exactly one manager before and after 2015
egen max_n_managers = max(n_managers), by(frame_id_numeric)
keep if max_n_managers == 1
drop max_n_managers

* now ready to compute statistics
collapse (mean) lnStilde (firstnm) person_id chi, by(frame_id_numeric before)
generate str when = cond(before, "_before", "_after")
drop before
reshape wide lnStilde person_id, i(frame_id_numeric) j(when) string
* verify that managers are different
count if person_id_before == person_id_after
drop if person_id_before == person_id_after

keep if !missing(lnStilde_before, lnStilde_after)
generate surplus_change = lnStilde_after - lnStilde_before
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

egen total_sales3 = total(sales), by(sector)
egen total_EBITDA3 = total(EBITDA1), by(sector)
egen total_sales4 = total(sales), by(teaor08_2d)
egen total_EBITDA4 = total(EBITDA2), by(teaor08_2d)

generate EBITDA3 = total_EBITDA3 / total_sales3 * sales
generate EBITDA4 = total_EBITDA4 / total_sales4 * sales

drop total_*

correlated EBITDA?
summarize EBITDA1, detail
count if EBITDA1 < 0 
* actual EBITDA is often negative, but inferring from sales is very similar

keep frame_id_numeric surplus_change chi sales EBITDA1 EBITDA2 
save "output/extract/manager_changes_2015.dta", replace

display "Extract 2 saved: Firms with manager changes in 2015"

* =============================================================================
* Extract 3: Connected component managers
* =============================================================================

* Get first year from CEO panel
use "input/ceo-panel/ceo-panel.dta", clear
collapse (min) entry_year = year (firstnm) birth_year hungarian_name male, by(person_id)
tempfile first_year
save `first_year'

use "temp/manager_value.dta", clear
collapse (firstnm) manager_skill, by(person_id)
keep if !missing(manager_skill)

merge 1:1 person_id using `first_year', keep(match) nogen
compress
save "output/extract/connected_managers.dta", replace

display "Extract 3 saved: Connected component managers with characteristics"
