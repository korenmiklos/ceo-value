clear all

use "temp/analysis-sample.dta"
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen

tabulate year, missing

replace max_employment = int(max_employment)
generate size = max_employment

recode size min/49 = 0 50/max = 1
keep if year == 2022
drop if max_employment < 10
drop if state_owned == 1
* too few firms in agri and const
drop if inlist(sector, 1, 6)

tabulate size foreign_owned, missing

generate manager_revenue = manager_skill / chi
collapse (mean) manager_revenue (count) n = manager_revenue, by(sector foreign_owned size)

replace manager_revenue = . if n < 30

* Sort data for consistent access  
sort size sector foreign_owned

* Create LaTeX table for small firms (size == 0)
file open table_small using "output/table/table4_panelA.tex", write replace

file write table_small "\begin{tabular}{lcc}" _n
file write table_small "\toprule" _n
file write table_small " & \multicolumn{2}{c}{Foreign owned} \\" _n
file write table_small "\cmidrule(lr){2-3}" _n
file write table_small "Sector & No & Yes \\" _n
file write table_small "\midrule" _n

* Get values directly from sorted data
* Manufacturing: rows 1 (domestic) and 2 (foreign) 
local val_dom = string(manager_revenue[1], "%9.3f")
local val_for = string(manager_revenue[2], "%9.3f")
file write table_small "Manufacturing & `val_dom' & `val_for' \\" _n

* Wholesale/Retail: rows 3 (domestic) and 4 (foreign)
local val_dom = string(manager_revenue[3], "%9.3f") 
local val_for = string(manager_revenue[4], "%9.3f")
file write table_small "Wholesale, Retail, Transportation & `val_dom' & `val_for' \\" _n

* Telecom: rows 5 (domestic) and 6 (foreign)
local val_dom = string(manager_revenue[5], "%9.3f")
local val_for = string(manager_revenue[6], "%9.3f")
file write table_small "Telecom and Business Services & `val_dom' & `val_for' \\" _n

* Nontradable: rows 7 (domestic) and 8 (foreign)
local val_dom = string(manager_revenue[7], "%9.3f")
local val_for = string(manager_revenue[8], "%9.3f")
file write table_small "Nontradable services & `val_dom' & `val_for' \\" _n

file write table_small "\bottomrule" _n
file write table_small "\end{tabular}" _n
file close table_small

* Create LaTeX table for large firms (size == 1) - no sector names
file open table_large using "output/table/table4_panelB.tex", write replace

file write table_large "\begin{tabular}{cc}" _n
file write table_large "\toprule" _n
file write table_large "\multicolumn{2}{c}{Foreign owned} \\" _n
file write table_large "\cmidrule(lr){1-2}" _n
file write table_large "No & Yes \\" _n
file write table_large "\midrule" _n

* Get values for large firms (size==1, starting at row 9)
* Manufacturing: rows 9 (domestic) and 10 (foreign)
local val_dom = string(manager_revenue[9], "%9.3f")
local val_for = string(manager_revenue[10], "%9.3f")
file write table_large "`val_dom' & `val_for' \\" _n

* Wholesale/Retail: rows 11 (domestic) and 12 (foreign)
local val_dom = string(manager_revenue[11], "%9.3f")
local val_for = string(manager_revenue[12], "%9.3f")
file write table_large "`val_dom' & `val_for' \\" _n

* Telecom: rows 13 (domestic) and 14 (foreign)
local val_dom = string(manager_revenue[13], "%9.3f")
local val_for = string(manager_revenue[14], "%9.3f")
file write table_large "`val_dom' & `val_for' \\" _n

* Nontradable: rows 15 (domestic) and 16 (foreign)
local val_dom = string(manager_revenue[15], "%9.3f")
local val_for = string(manager_revenue[16], "%9.3f")
file write table_large "`val_dom' & `val_for' \\" _n

file write table_large "\bottomrule" _n
file write table_large "\end{tabular}" _n
file close table_large

display "Table 4 panels A and B created successfully"