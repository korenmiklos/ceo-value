clear all
use "../../temp/analysis-sample.dta", clear
sort frame_id_numeric year ceo_spell
by frame_id_numeric: gen ceo_switch = ceo_spell != ceo_spell[_n-1]  if _n > 1
replace ceo_switch = 0 if missing(ceo_switch)

collapse (count) n_firms = frame_id_numeric (sum) ceo_switch (mean) employment, by(year)
mkmat n_firms ceo_switch employment, matrix(YearTab) rownames(year)

matrix colnames YearTab = "Firms" "CEO Switches" "Employment"

esttab matrix(YearTab) using "table/firm-year-descriptives.tex", replace ///
    noobs nonumber nomtitle fragment ///
