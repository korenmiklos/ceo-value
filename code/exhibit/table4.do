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

/*
CREATE these tables from actual data in latex to output/table/table4.tex

. table sector foreign_owned if size == 0, stat(mean manager_revenue )

----------------------------------------------------------------------
                                    |           Foreign owned         
                                    |         0           1      Total
------------------------------------+---------------------------------
sector                              |                                 
  Manufacturing                     |  .1139226   -.0359089   .0390069
  Wholesale, Retail, Transportation |  .2225065     .398913   .3107098
  Telecom and Business Services     |  .1257979    .2921891   .2089935
  Nontradable services              |  .0006354    .1822135   .0914245
  Total                             |  .1157156    .2093517   .1625336
----------------------------------------------------------------------

. table sector foreign_owned if size == 1, stat(mean manager_revenue )

----------------------------------------------------------------------
                                    |           Foreign owned         
                                    |         0           1      Total
------------------------------------+---------------------------------
sector                              |                                 
  Manufacturing                     |  .1779291    .7897289    .483829
  Wholesale, Retail, Transportation |  .0948672     .994335   .5446011
  Telecom and Business Services     |  .3858612   -.1116871   .1370871
  Nontradable services              |  .1310089    .6432116   .3871103
  Total                             |  .1974166    .5788971   .3881569
----------------------------------------------------------------------
*/