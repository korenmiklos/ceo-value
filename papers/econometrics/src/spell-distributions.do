use "../../temp/analysis-sample.dta", clear


egen first_exit_as_ceo = min(year) if exit, by(frame_id_numeric person_id)
egen first_year_as_ceo = min(year), by(frame_id_numeric person_id)

egen match_tag = tag(frame_id_numeric person_id)
keep if match_tag 

generate tenure = first_exit_as_ceo - first_year_as_ceo + 1 if first_exit_as_ceo < 2021
egen max_tenure = max(tenure), by(frame_id_numeric person_id)

label variable tenure "Length of first spell at firm (year)"


histogram tenure [fw=max_tenure], disc ///
	scheme(s2mono) graphregion(color(white)) ///
	
graph export "figure/ceo-spell-distributions.pdf", replace
