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

egen firm_year_tag = tag(frame_id_numeric year)

collapse (sum) n_firms=firm_year_tag (percent) pct=frame_id_numeric, by(ind_cat)
sort ind_cat
mkmat n_firms pct, matrix(IndTab) rownames(ind_cat)


file open tab using "table/industry-descriptives.tex", write replace
file write tab "\begin{tabular}{l*{2}{c}}" _n
file write tab "\hline\hline" _n
file write tab "Industry & N & \% \\" _n
file write tab "\hline" _n


forvalues cat = 1/6 {
    local cat_label : label ind_cat_lbl `cat'
    local rname = "`cat_label'"
    local n_str  = string(n_firm[`cat'], "%5.0f")
    local pct_str = string(pct[`cat'], "%5.1f")
    file write tab "`rname' & $`n_str'$ & $`pct_str'$ \\" _n
}

file write tab "\hline\hline" _n
file write tab "\end{tabular}" _n
file close tab
