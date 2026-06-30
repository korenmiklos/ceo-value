clear all
use "../../temp/analysis-sample.dta", clear

collapse (count) n_firm=frame_id_numeric (percent) pct=frame_id_numeric, by(teaor08_1d)
mkmat n_firm pct, matrix(IndTab) rownames(teaor08_1d)

file open tab using "table/industry-descriptives.tex", write replace
file write tab "\begin{tabular}{l*{2}{c}}" _n
file write tab "\hline\hline" _n
file write tab "Industry & No.obs & \% \\" _n
file write tab "\hline" _n

local rnames: rowfullnames IndTab

forvalues r = 1/`=rowsof(IndTab)'{
  local rname : word `r' of `rnames'
  local rowcontent = ""
  forvalues c = 1/`=colsof(IndTab)' {
    local val = IndTab[`r', `c']
    local val_str = string(`val', "%5.0f")
    local rowcontent = "`rowcontent' & `val_str'"
    }
  file write tab "`rname' `rowcontent' \\" _n
}

file write tab "\hline\hline" _n
file write tab "\end{tabular}" _n
file close tab
