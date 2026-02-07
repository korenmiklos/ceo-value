use "../../temp/analysis-sample.dta", clear


egen first_exit_as_ceo = min(cond(leaving_ceo == 1, year,.)), by(frame_id_numeric person_id)
egen first_year_as_ceo = min(year), by(frame_id_numeric person_id)
generate tenure = first_exit_as_ceo - first_year_as_ceo + 1 if year < 2022
label variable tenure "Length of first spell at firm (year)"

preserve
egen match_tag = tag(frame_id_numeric person_id)
keep if match_tag 

histogram tenure, disc ///
	scheme(s2mono) graphregion(color(white)) ///
	
graph export "figure/ceo-spell-distributions.pdf", replace
restore

histogram tenure, disc ///
	scheme(s2mono) graphregion(color(white)) ///
	
graph export "figure/ceo-spell-distributions-weighted.pdf", replace
