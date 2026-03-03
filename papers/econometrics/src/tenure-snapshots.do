use "../../temp/analysis-sample.dta", clear

egen first_year = min(year), by(frame_id_numeric ceo_spell)
egen last_year = max(year), by(frame_id_numeric ceo_spell)
gen tenure = last_year - first_year + 1

histogram tenure if inlist(year, 1995, 2000, 20005, 2010, 2015, 2020), ///
  by(year) disc scheme(s2mono) graphregion(color(white))
graph export "figure/tenure-snapshots.pdf", replace
