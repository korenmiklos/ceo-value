clear all
use "../../temp/analysis-sample.dta", clear
sort frame_id_numeric year ceo_spell
by frame_id_numeric: gen ceo_switch = ceo_spell != ceo_spell[_n-1]  if _n > 1
replace ceo_switch = 0 if missing(ceo_switch)

collapse (count) n_firms = frame_id_numeric (sum) ceo_switch (mean) employment, by(year)
mkmat n_firms ceo_switch employment, matrix(YearTab) rownames(year)

matrix colnames YearTab = "Firms" "CEO Switches" "Employment"

file open tab using "table/firm-year-descriptives.tex", write replace
file write tab "\begin{tabular}{l*{3}{c}}" _n
file write tab "\hline\hline" _n
file write tab "Year & Frims & CEO Switches & Employment \\" _n
file write tab "\hline" _n

local rnames: rowfullnames YearTab

forvalues r = 1/`=rowsof(YearTab)'{
    local rname : word `r' of `rnames'
    local rowcontent = ""
    forvalues c = 1/`=colsof(YearTab)' {
        local val = YearTab[`r', `c']
        local val_str = string(`val', "%5.0f")
        local rowcontent = "`rowcontent' & `val_str'"
        }
    file write tab "`rname' `rowcontent' \\" _n
}

file write tab "\hline\hline" _n
file write tab "\end{tabular}" _n
file close tab
