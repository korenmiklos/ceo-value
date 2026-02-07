use "../../temp/analysis-sample.dta", clear

egen firm_ceo_tag = tag(frame_id_numeric person_id)
bysort frame_id_numeric: egen n_ceos = total(firm_ceo_tag)
collapse (firstnm) n_ceos, by(frame_id_numeric)
estpost tabulate n_ceos
esttab using "table/managers-in-lifetime.tex", cell(b pct) replace
