* Import the large connected component managers with component IDs
preserve
import delimited "temp/large_component_managers.csv", clear
tempfile managers_in_large_components
save `managers_in_large_components'
restore

* Merge component IDs
merge m:1 person_id using `managers_in_large_components'
replace component_id = 0 if _merge == 1
drop _merge

* Display component distribution
tabulate component_id, missing