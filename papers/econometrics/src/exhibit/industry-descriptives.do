clear all
use "../../temp/analysis-sample.dta", clear

collapse (firstnm) teaor08_1d, by(frame_id_numeric)

local texheader1 "\begin{tabular}{l*{2}{c}}"
local texheader2 "\hline\hline"
local texheader3 "Statistic & P25 & P50 & P75 \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"

file open tab using "table/switch-descriptives.tex", write replace
file write tab "\begin{tabular}{lccccc}" _n
file write tab "\hline\hline" _n
file write tab " & Employment & Sales & Productivity & ROA & Firms \\" _n
file write tab "\hline" _n


estpost tabulate teaor08_1d
esttab . using "table/industry-descriptives.tex", append ///
    cells("b(fmt(0)) pct(fmt(1))") ///
    noobs nonumber nomtitle fragment ///
    collabels("Industry" "No. obs" "\%") ///


file write tab "\hline\hline" _n
file write tab "\end{tabular}" _n
file close tab
