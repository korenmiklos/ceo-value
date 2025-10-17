*! version 1.0.0  17oct2025
*! Create non-overlapping 3-year windows with firm-year-manager observations for variance-covariance decomposition

use "temp/analysis-sample.dta", clear

egen firm_tag = tag(frame_id_numeric)
count if firm_tag
display "Total firms: " r(N)

egen manager_tag = tag(person_id)
count if manager_tag
display "Total managers: " r(N)

drop firm_tag manager_tag

generate window_id = .
local window_id = 1
forvalues start_year = 1992(3)2019 {
    local end_year = `start_year' + 2
    replace window_id = `window_id' if inrange(year, `start_year', `end_year')
    local window_id = `window_id' + 1
}

keep if !missing(window_id)
keep if !missing(lnR)
keep if !missing(frame_id_numeric)
keep if !missing(person_id)
keep if !missing(year)

tabulate window_id, missing

keep window_id frame_id_numeric person_id lnR year

order window_id year frame_id_numeric person_id lnR

export delimited using "temp/sorting_windows.csv", replace

egen window_tag = tag(window_id)
egen firm_window_tag = tag(frame_id_numeric window_id)
egen manager_window_tag = tag(person_id window_id)
egen firm_year_tag = tag(frame_id_numeric year)

display "==================================================================="
display "Summary statistics:"
tabulate window_id if window_tag, missing
display ""
display "Firm-window combinations:"
count if firm_window_tag
display ""
display "Manager-window combinations:"
count if manager_window_tag
display ""
display "Firm-year observations:"
count if firm_year_tag
display ""
display "Total observations:"
count
display "==================================================================="
display "Exported to temp/sorting_windows.csv"
