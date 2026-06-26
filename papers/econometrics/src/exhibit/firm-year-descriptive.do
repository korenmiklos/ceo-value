clear all
use "../../temp/analysis-sample.dta", clear

sort frame_id_numeric year ceo_spell
by frame_id_numeric: gen ceo_switch = ceo_spell - ceo_spell[_n-1]  if _n > 1
replace ceo_switch = 0 if missing(ceO_switch)

collapse (count) n_firms = frame_id_numeric (sum) ceo_switch (mean) employment, by(year)
* Create summary statistics
estpost tabstat n_firms ceo_switch employment, by(year) statistics(mean) nototal

* Export to LaTeX
esttab using "table/firm-year-descriptives.tex", replace ///
       cells("n_firms(fmt(0)) ceo_switch(fmt(0)) employment(fmt(0))") ///
       noobs nonumber nomtitle ///
       collabels("Firms" "CEO Switches" "Avg. Emplyoment") ///
       title("Firm Descriptives by Year")
