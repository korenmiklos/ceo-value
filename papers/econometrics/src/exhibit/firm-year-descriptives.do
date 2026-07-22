clear all
use "../../temp/analysis-sample.dta", clear
sort frame_id_numeric year ceo_spell
by frame_id_numeric: gen ceo_switch = ceo_spell != ceo_spell[_n-1]  if _n > 1
replace ceo_switch = 0 if missing(ceo_switch)
egen firm_year_tag = tag(frame_id_numeric year)

preserve
collapse (sum) n_firms = firm_year_tag ceo_switch (mean) employment
tempfile totals
save `totals'
restore

collapse (sum) n_firms = firm_year_tag ceo_switch (mean) employment, by(year)
keep if inlist(year, 1992, 1995, 2000, 2005, 2010, 2015, 2020, 2023)
append using `totals'
sort year
tostring year, gen(year_str) format(%9.0f) force
replace year_str = "Total" if year == .
order year_str, first
mkmat n_firms ceo_switch employment, matrix(YearTab) rownames(year_str)

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
