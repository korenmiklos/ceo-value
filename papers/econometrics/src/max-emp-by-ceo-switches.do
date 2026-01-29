use "../../temp/analysis-sample.dta", clear

gen had_ceo_switches = (max_ceo_spell >=2)

collapse (firstnm) max_emp had_ceo_switches, by(frame_id_numeric)

estpost tabstat max_emp, by(had_ceo_switches) statistics(mean sd p50 min max n) nototal

* Export to LaTeX
esttab using "table/max-emp-by-ceo-switches.tex", replace ///
       cells("max_emp(fmt(0))") ///
       noobs nonumber nomtitle ///
       collabels("Size") ///
       title("Maximum size of firms (in employment)")
