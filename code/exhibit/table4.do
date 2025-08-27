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

replace manager_revenue = . if n < 50

* Create LaTeX tables
* Reshape data to wide format for easier access
preserve
keep if size == 0
reshape wide manager_revenue n, i(sector) j(foreign_owned)

* Create LaTeX table for small firms (size == 0)
file open table_small using "output/table/table4_panelA.tex", write replace

file write table_small "\begin{tabular}{l*{3}{c}}" _n
file write table_small "\toprule" _n
file write table_small " & \multicolumn{2}{c}{Foreign owned} & \\" _n
file write table_small "\cmidrule(lr){2-3}" _n
file write table_small "Sector & No & Yes & Total \\" _n
file write table_small "\midrule" _n

* Manufacturing
sum manager_revenue0 if sector == 2
local mfg_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 2  
local mfg_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 2
sum temp
local mfg_tot = string(r(mean), "%9.3f")
drop temp
file write table_small "Manufacturing & `mfg_dom' & `mfg_for' & `mfg_tot' \\" _n

* Wholesale, Retail, Transportation
sum manager_revenue0 if sector == 3
local wrt_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 3
local wrt_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 3
sum temp
local wrt_tot = string(r(mean), "%9.3f")
drop temp
file write table_small "Wholesale, Retail, Transportation & `wrt_dom' & `wrt_for' & `wrt_tot' \\" _n

* Telecom and Business Services
sum manager_revenue0 if sector == 4
local tbs_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 4
local tbs_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 4
sum temp
local tbs_tot = string(r(mean), "%9.3f")
drop temp
file write table_small "Telecom and Business Services & `tbs_dom' & `tbs_for' & `tbs_tot' \\" _n

* Nontradable services
sum manager_revenue0 if sector == 5
local nts_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 5
local nts_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 5
sum temp
local nts_tot = string(r(mean), "%9.3f")
drop temp
file write table_small "Nontradable services & `nts_dom' & `nts_for' & `nts_tot' \\" _n

file write table_small "\midrule" _n

* Total row
egen temp_dom = mean(manager_revenue0)
egen temp_for = mean(manager_revenue1)
egen temp_tot = rowmean(manager_revenue0 manager_revenue1)
sum temp_dom
local tot_dom = string(r(mean), "%9.3f")
sum temp_for
local tot_for = string(r(mean), "%9.3f")
sum temp_tot
local tot_tot = string(r(mean), "%9.3f")
file write table_small "Total & `tot_dom' & `tot_for' & `tot_tot' \\" _n

file write table_small "\bottomrule" _n
file write table_small "\end{tabular}" _n
file close table_small

restore

* Create LaTeX table for large firms (size == 1)
preserve
keep if size == 1
reshape wide manager_revenue n, i(sector) j(foreign_owned)

file open table_large using "output/table/table4_panelB.tex", write replace

file write table_large "\begin{tabular}{l*{3}{c}}" _n
file write table_large "\toprule" _n
file write table_large " & \multicolumn{2}{c}{Foreign owned} & \\" _n
file write table_large "\cmidrule(lr){2-3}" _n
file write table_large "Sector & No & Yes & Total \\" _n
file write table_large "\midrule" _n

* Manufacturing
sum manager_revenue0 if sector == 2
local mfg_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 2
local mfg_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 2
sum temp
local mfg_tot = string(r(mean), "%9.3f")
drop temp
file write table_large "Manufacturing & `mfg_dom' & `mfg_for' & `mfg_tot' \\" _n

* Wholesale, Retail, Transportation
sum manager_revenue0 if sector == 3
local wrt_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 3
local wrt_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 3
sum temp
local wrt_tot = string(r(mean), "%9.3f")
drop temp
file write table_large "Wholesale, Retail, Transportation & `wrt_dom' & `wrt_for' & `wrt_tot' \\" _n

* Telecom and Business Services
sum manager_revenue0 if sector == 4
local tbs_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 4
local tbs_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 4
sum temp
local tbs_tot = string(r(mean), "%9.3f")
drop temp
file write table_large "Telecom and Business Services & `tbs_dom' & `tbs_for' & `tbs_tot' \\" _n

* Nontradable services
sum manager_revenue0 if sector == 5
local nts_dom = string(r(mean), "%9.3f")
sum manager_revenue1 if sector == 5
local nts_for = string(r(mean), "%9.3f")
egen temp = rowmean(manager_revenue0 manager_revenue1) if sector == 5
sum temp
local nts_tot = string(r(mean), "%9.3f")
drop temp
file write table_large "Nontradable services & `nts_dom' & `nts_for' & `nts_tot' \\" _n

file write table_large "\midrule" _n

* Total row
egen temp_dom = mean(manager_revenue0)
egen temp_for = mean(manager_revenue1)
egen temp_tot = rowmean(manager_revenue0 manager_revenue1)
sum temp_dom
local tot_dom = string(r(mean), "%9.3f")
sum temp_for
local tot_for = string(r(mean), "%9.3f")
sum temp_tot
local tot_tot = string(r(mean), "%9.3f")
file write table_large "Total & `tot_dom' & `tot_for' & `tot_tot' \\" _n

file write table_large "\bottomrule" _n
file write table_large "\end{tabular}" _n
file close table_large

restore

display "Table 4 panels A and B created successfully"