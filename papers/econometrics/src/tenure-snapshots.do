use "../../temp/analysis-sample.dta", clear

egen firm_ceo_year_tag = tag(frame_id_numeric person_id year)
keep if firm_ceo_year_tag
drop if exit

histogram ceo_tenure if inlist(year, 1995, 2000, 20005, 2010, 2015, 2020), ///
  by(year) disc scheme(s2mono) graphregion(color(white))
graph export "figure/tenure-snapshots.pdf", replace
