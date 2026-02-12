*! version 1.0.0 2026-02-12
* =============================================================================
* Fill potholes of 1 or 2 years in CEO spells and compute spell boundaries
* =============================================================================
* Requires: frame_id_numeric person_id year in memory
* Creates: spell start_year
* Preserves all other variables in the dataset

confirm numeric variable frame_id_numeric
confirm numeric variable person_id
confirm numeric variable year

* =============================================================================
* POTHOLE FILLING
* =============================================================================
capture drop fp
egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

* we are glossing over potholes of 1 or 2 years
bysort fp (year): generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
* number of clones to create of CEO
generate clones = 1
forvalues t = 1/2 {
    replace clones = `t' + 1 if gap == `t'
}
expand clones
bysort fp year: replace year = year - _n + 1

drop gap clones fp

* test whether potholes have been filled
bysort frame_id_numeric person_id (year): generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
tabulate gap, missing
assert gap == 0 | gap > 2
drop gap

* =============================================================================
* SPELL COMPUTATION
* =============================================================================
egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

generate byte entering_ceo = missing(L.year)

* the same person may have multiple spells at the firm
bysort frame_id_numeric person_id (year): generate spell = sum(entering_ceo)
egen start_year = min(year), by(frame_id_numeric person_id spell)

drop entering_ceo fp
