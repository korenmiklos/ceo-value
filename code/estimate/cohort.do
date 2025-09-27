use "temp/unfiltered.dta", clear
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen

* for babyboom, we measure manager skills in revenue units, not as TFP
replace manager_skill = manager_skill / chi
* only deal with hungarian CEOs
generate byte hungarian_name = !missing(male)
keep if hungarian_name

keep if !missing(sales)
egen N_jobs = total(1), by(person_id year)
tabulate N_jobs
drop if N_jobs > 4
* keep largest firm only if multiple jobs
bysort person_id year (sales): keep if _n == _N
tabulate N_jobs
drop N_jobs

egen first_year = min(year), by(person_id)
tabulate first_year founder

generate cohort = int(first_year/5)*5
tabulate cohort founder

generate birth_cohort = int(birth_year/5)*5

egen skill_group = group(birth_cohort male)
egen tag = tag(person_id first_year skill_group)
egen n = total(tag), by(first_year skill_group)
* 1986 is the first measured year, captures the entire 1980s
replace n = n / 7 if first_year == 1986
generate ln_n = ln(n)

local controls male ceo_age ceo_age_sq founder firm_age firm_age_sq
local FEs teaor08_2d##year
local sample inrange(ceo_age, 18, 75)

* firm size goes down. entry goes up
reghdfe lnR ib1985.cohort `controls' if `sample', a(`FEs') cluster(first_year )
reghdfe ln_n ib1985.cohort `controls' if `sample', a(`FEs') cluster(first_year )

* ln_n captures degree of entry in cohort, its coefficient is -1/theta
reghdfe lnR ln_n `controls' if `sample', a(`FEs') cluster(first_year )
* if skill groups have difference baseline skills or different sizes (demographics), this can be taken out by fixed effects
reghdfe lnR ln_n `controls' if `sample', a(`FEs' skill_group) cluster(first_year )
* only use stable, post-EU years
reghdfe lnR ln_n `controls' if `sample' & year >= 2004, a(`FEs' skill_group) cluster(first_year )
* exclude pre-transition entry - this starting in 1992 are already post-transition
reghdfe lnR ln_n `controls' if `sample' & first_year >= 1992, a(`FEs' skill_group) cluster(first_year )
* exclude founders
reghdfe lnR ln_n `controls' if `sample' & !founder, a(`FEs' skill_group) cluster(first_year )

* add firm fixed effects - results are about half
reghdfe lnR ln_n `controls' if `sample', a(`FEs' frame_id_numeric) cluster(first_year )
reghdfe lnR ln_n `controls' if `sample', a(`FEs' skill_group frame_id_numeric) cluster(first_year )

* study founder discount for exact same person
reghdfe lnR founder if `sample', a(`FEs' person_id) cluster(person_id)
