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

* Create LaTeX table for small firms (size == 0)
file open table_small using "output/table/table4_panelA.tex", write replace

file write table_small "\begin{tabular}{lcc}" _n
file write table_small "\toprule" _n
file write table_small " & \multicolumn{2}{c}{Foreign owned} \\" _n
file write table_small "\cmidrule(lr){2-3}" _n
file write table_small "Sector & No & Yes \\" _n
file write table_small "\midrule" _n

* Loop through sectors and foreign ownership to write values
forvalues s = 2/5 {
    * Get sector name
    local sector_name ""
    if `s' == 2 local sector_name "Manufacturing"
    if `s' == 3 local sector_name "Wholesale, Retail, Transportation"
    if `s' == 4 local sector_name "Telecom and Business Services"
    if `s' == 5 local sector_name "Nontradable services"
    
    * Get values for domestic and foreign
    quietly sum manager_revenue if sector == `s' & foreign_owned == 0 & size == 0
    if r(N) > 0 {
        local val_dom = string(r(mean), "%9.3f")
    }
    else {
        local val_dom "."
    }
    
    quietly sum manager_revenue if sector == `s' & foreign_owned == 1 & size == 0
    if r(N) > 0 {
        local val_for = string(r(mean), "%9.3f")
    }
    else {
        local val_for "."
    }
    
    file write table_small "`sector_name' & `val_dom' & `val_for' \\" _n
}

file write table_small "\bottomrule" _n
file write table_small "\end{tabular}" _n
file close table_small

* Create LaTeX table for large firms (size == 1)
file open table_large using "output/table/table4_panelB.tex", write replace

file write table_large "\begin{tabular}{lcc}" _n
file write table_large "\toprule" _n
file write table_large " & \multicolumn{2}{c}{Foreign owned} \\" _n
file write table_large "\cmidrule(lr){2-3}" _n
file write table_large "Sector & No & Yes \\" _n
file write table_large "\midrule" _n

* Loop through sectors and foreign ownership to write values
forvalues s = 2/5 {
    * Get sector name
    local sector_name ""
    if `s' == 2 local sector_name "Manufacturing"
    if `s' == 3 local sector_name "Wholesale, Retail, Transportation"
    if `s' == 4 local sector_name "Telecom and Business Services"
    if `s' == 5 local sector_name "Nontradable services"
    
    * Get values for domestic and foreign
    quietly sum manager_revenue if sector == `s' & foreign_owned == 0 & size == 1
    if r(N) > 0 {
        local val_dom = string(r(mean), "%9.3f")
    }
    else {
        local val_dom "."
    }
    
    quietly sum manager_revenue if sector == `s' & foreign_owned == 1 & size == 1
    if r(N) > 0 {
        local val_for = string(r(mean), "%9.3f")
    }
    else {
        local val_for "."
    }
    
    file write table_large "`sector_name' & `val_dom' & `val_for' \\" _n
}

file write table_large "\bottomrule" _n
file write table_large "\end{tabular}" _n
file close table_large

display "Table 4 panels A and B created successfully"