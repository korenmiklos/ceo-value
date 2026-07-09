clear all
use "../../temp/analysis-sample.dta", clear

gen byte ind_cat = .
replace ind_cat = 1 if teaor08_1d == "A"
replace ind_cat = 2 if inlist(teaor08_1d, "B","C","D","E")
replace ind_cat = 3 if teaor08_1d == "F"
replace ind_cat = 4 if teaor08_1d == "G"
replace ind_cat = 5 if inlist(teaor08_1d, "M","N")
replace ind_cat = 6 if missing(ind_cat) & !missing(teaor08_1d)
replace teaor08_1d = "Missing" if missing(teaor08_1d)

label define ind_cat_lbl ///
    1 "Agriculture" ///
    2 "Industry" ///
    3 "Construction" ///
    4 "Trade" ///
    5 "Business Services" ///
    6 "Other Services"
label values ind_cat ind_cat_lbl

collapse (count) n_firm=frame_id_numeric (percent) pct=frame_id_numeric, by(ind_cat teaor08_1d)

sort ind_cat teaor08_1d

* számláló ahány sora van a táblának (industry sorok, group header sorok nélkül)
local N = _N

file open tab using "table/industry-descriptives.tex", write replace
file write tab "\begin{tabular}{l*{2}{c}}" _n
file write tab "\hline\hline" _n
file write tab "Industry & N & \% \\" _n
file write tab "\hline" _n

local prev_cat = .

forvalues r = 1/`N' {
    local this_cat = ind_cat[`r']

    * ha új csoportba lépünk, írjunk ki egy fejléc-sort
    if `this_cat' != `prev_cat' {
        local cat_label : label ind_cat_lbl `this_cat'
        file write tab "\multicolumn{3}{l}{\textit{`cat_label'}} \\" _n
    }

    local rname = teaor08_1d[`r']
    local n_str  = string(n_firm[`r'], "%5.0f")
    local pct_str = string(pct[`r'], "%5.1f")

    file write tab "\quad `rname' & `n_str' & `pct_str' \\" _n

    local prev_cat = `this_cat'
}

file write tab "\hline\hline" _n
file write tab "\end{tabular}" _n
file close tab
