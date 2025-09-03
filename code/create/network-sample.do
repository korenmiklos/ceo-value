* Import the large connected component managers with component IDs
preserve
import delimited "temp/large_component_managers.csv", clear
tempfile managers_in_large_components
save `managers_in_large_components'
restore

* Merge component IDs
merge m:1 person_id using `managers_in_large_components'
replace component_id = 0 if _merge == 1
replace component_size = 0 if _merge == 1

* define network sample so that we can reuse it in all tables and regressions
generate byte giant_component = (component_id == 1)
generate byte connected_components = (component_size >= 30)

drop _merge

* Display component distribution
tabulate component_id, missing