*! version 1.0 2025-08-01
*! Extract manager value data for external analysis

* Standard setup
clear all
set more off
cap log close

log using temp/extract.log, text replace

* Create output directory if it doesn't exist
cap mkdir output/extracts

* Load manager value data with firm fixed effects
use temp/manager_value.dta, clear

* =============================================================================
* Extract 1: Year 2022 - firm FE and manager value
* =============================================================================

preserve
	keep if year == 2022
	rename frame_id_numeric frame_id
	rename manager_skill manager_value
	keep frame_id firm_fixed_effect manager_value
	compress
	save "output/extracts/extract1_2022_values.dta", replace
restore

di "Extract 1 saved: 2022 firm FE and manager values"

* =============================================================================
* Extract 2: Manager changes in 2015
* =============================================================================

* Load analysis sample for detailed firm-year data
use temp/analysis-sample.dta, clear

* Keep only firms with exactly one CEO
keep if n_ceo == 1

* Identify managers who started in 2015
bys person_id: egen first_year = min(year)
gen started_2015 = (first_year == 2015)

* Identify firms that had a manager change in 2015
bys frame_id: egen has_2015_change = max(started_2015)
keep if has_2015_change == 1

* Sort by firm and year
sort frame_id year

* Identify the manager before and after 2015
bys frame_id: gen before_manager = person_id if year < 2015
bys frame_id: gen after_manager = person_id if year >= 2015

* Fill in manager IDs across years
bys frame_id: egen before_manager_id = mode(before_manager), minmode
bys frame_id: egen after_manager_id = mode(after_manager), minmode

* Check stability: before manager unchanged 2012-2013
preserve
	keep if inrange(year, 2012, 2013)
	bys frame_id: egen n_before_managers = nvals(person_id)
	keep frame_id n_before_managers
	duplicates drop
	tempfile before_stable
	save `before_stable'
restore

* Check stability: after manager unchanged 2015-2017
preserve
	keep if inrange(year, 2015, 2017)
	bys frame_id: egen n_after_managers = nvals(person_id)
	keep frame_id n_after_managers
	duplicates drop
	tempfile after_stable
	save `after_stable'
restore

* Merge stability checks
merge m:1 frame_id using `before_stable', nogen
merge m:1 frame_id using `after_stable', nogen

* Keep only stable transitions
keep if n_before_managers == 1 & n_after_managers == 1

* Calculate average lnStilde for 2012-2013
preserve
	keep if inrange(year, 2012, 2013)
	collapse (mean) lnStilde_before = lnStilde, by(frame_id)
	tempfile before_avg
	save `before_avg'
restore

* Calculate average lnStilde for 2016-2017
preserve
	keep if inrange(year, 2016, 2017)
	collapse (mean) lnStilde_after = lnStilde, by(frame_id)
	tempfile after_avg
	save `after_avg'
restore

* Combine results
use `before_avg', clear
merge 1:1 frame_id using `after_avg', nogen keep(match)

compress
save "output/extracts/extract2_manager_changes_2015.dta", replace

di "Extract 2 saved: Firms with manager changes in 2015"

* =============================================================================
* Extract 3: Connected component managers
* =============================================================================

* Load manager value data
use temp/manager_value.dta, clear

* Load connected component managers
preserve
	import delimited "temp/large_component_managers.csv", clear
	keep if component_id == 1
	keep person_id
	tempfile connected_managers
	save `connected_managers'
restore

* Keep only managers in connected component
merge m:1 person_id using `connected_managers', keep(match) nogen

* Keep one observation per manager (most recent year)
bys person_id: egen max_year = max(year)
keep if year == max_year
duplicates drop person_id, force

* Get first year from CEO panel
preserve
	use temp/ceo-panel.dta, clear
	bys person_id: egen first_ceo_year = min(year)
	keep person_id first_ceo_year
	duplicates drop
	tempfile first_year
	save `first_year'
restore

* Merge first year information
merge 1:1 person_id using `first_year', keep(match) nogen

* Keep relevant variables
rename manager_skill manager_value
keep person_id manager_value gender birth_year first_ceo_year

compress
save "output/extracts/extract3_connected_managers.dta", replace

di "Extract 3 saved: Connected component managers with characteristics"

log close