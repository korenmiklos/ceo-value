* Import the largest connected component managers
preserve
import delimited "temp/largest_component_managers.csv", clear
tempfile managers_in_largest_component
save `managers_in_largest_component'
restore

* Create connected_component dummy variable
merge m:1 person_id using `managers_in_largest_component'
generate connected_component = (_merge == 3)
drop _merge

* Display counts
tabulate connected_component, missing