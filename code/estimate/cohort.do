use "temp/unfiltered.dta", clear
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen

* for babyboom, we measure manager skills in revenue units, not as TFP
replace manager_skill = manager_skill / chi
keep if component_id > 0
generate byte hungarian_name = !missing(male)

keep if hungarian_name

collapse (mean) manager_skill (min) birth_year first_year = year (max) male last_year = year (min) component_id (max) component_size, by(person_id founder)
reshape wide manager_skill first_year last_year birth_year male, i(person_id) j(founder)

* relatively few overlap, use the first ceo spell
egen first_year = rowmin(first_year?)
egen last_year = rowmax(last_year?)
egen manager_skill = rowmean(manager_skill?)
egen birth_year = rowmin(birth_year?)
egen male = rowmax(male?)

generate byte founder = first_year0 > first_year
tabulate first_year founder

generate cohort = int(first_year/5)*5
tabulate cohort founder

generate birth_cohort = int(birth_year/5)*5

egen n = count(person_id), by(first_year founder male)
generate ln_n = ln(n)

local controls male
local FEs component_id birth_cohort
local sample birth_year <= 2000

* different components may have different means
reghdfe manager_skill ib1985.cohort `controls' if founder & `sample', a(`FEs') cluster(first_year )
reghdfe manager_skill ib1985.cohort `controls' if !founder & `sample', a(`FEs') cluster(first_year )

reghdfe manager_skill ln_n `controls' if !founder & `sample', a(`FEs') cluster(first_year )
reghdfe manager_skill ln_n `controls' if founder & `sample', a(`FEs') cluster(first_year )
reghdfe manager_skill i.founder##c.ln_n `controls' if `sample', a(`FEs') cluster(first_year )
