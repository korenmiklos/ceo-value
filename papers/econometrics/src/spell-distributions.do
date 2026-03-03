use "../../temp/analysis-sample.dta", clear

egen first_year = min(year), by(frame_id_numeric ceo_spell)
egen last_year = max(year), by(frame_id_numeric ceo_spell)
gen tenure = last_year - first_year + 1
label variable tenure "Length of first spell at firm (year)"

preserve
duplicates drop frame_id_numeric ceo_spell, force

histogram tenure, disc ///
	scheme(s2mono) graphregion(color(white)) ///

graph export "figure/ceo-spell-distributions.pdf", replace
restore

histogram tenure, disc ///
	scheme(s2mono) graphregion(color(white)) ///

graph export "figure/ceo-spell-distributions-weighted.pdf", replace
