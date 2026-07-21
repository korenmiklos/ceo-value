use "../../temp/unfiltered.dta", clear

replace n_ceo = 5 if n_ceo>4
tab n_ceo, matcell(freq1)
local N1 = r(N)

egen firm_ceo_tag = tag(frame_id_numeric ceo_spell)
collapse (sum) n_ceos = firm_ceo_tag, by(frame_id_numeric)
replace n_ceos = 5 if n_ceos>4
tab n_ceos, matcell(freq2)
local N2 = r(N)

* =============================================================================
* Compute manager loyalty statistics
* =============================================================================

* Save firm list from unfiltered sample
preserve
    keep frame_id_numeric
    egen firm_tag = tag(frame_id_numeric)
    keep if firm_tag
    tempfile firm_list
    save `firm_list'
restore

* Load manager-firm facts, restrict to sample firms
use "../../temp/manager-firm-facts.dta", clear
merge m:1 frame_id_numeric using `firm_list', keep(match) nogen

* Count distinct firms per manager (each row is unique firm-person pair)
bysort person_id: generate byte n_firms = _N
generate byte single_firm_mgr = (n_firms == 1)

* % of managers managing exactly 1 firm
egen mgr_tag = tag(person_id)
count if mgr_tag
local N_mgr = r(N)
count if mgr_tag & single_firm_mgr
local single_mgr = r(N)
local pct_single_mgr = 100 * r(N) / `N_mgr'

* of firms where ALL managers are single-firm
bysort frame_id_numeric: egen byte has_multi = max(!single_firm_mgr)
count if firm_tag
local N_firm = r(N)
count if firm_tag & !has_multi
local firms_all_single = r(N)
local pct_firms_all_single = 100 * r(N) / `N_firm'

file open fh using "table/ceo-counts.tex", write replace
file write fh "\begin{tabular}{*{5}{c}}" _n
file write fh "\toprule" _n
file write fh "CEOs & Firm-years & \% & Firms & \% \\" _n
file write fh "\midrule" _n

forvalues i = 1/5 {
      local label1 = cond(`i' == 5, "4+", "`=`i'-1'")
      local label2 = cond(`i' == 5, "4+", "`i'")
      local f1 : display %12.0fc freq1[`i', 1]
      local p1 : display %5.1f 100 * freq1[`i', 1] / `N1'
      local f2 : display %12.0fc freq2[`i', 1]
      local p2 : display %5.1f 100 * freq2[`i', 1] / `N2'
      file write fh "`label1' & `f1' & `p1'\% & `label2' & `p2'\% \\" _n
  }

file write fh "\midrule" _n
local t1 : display %12.0fc `N1'
local t2 : display %12.0fc `N2'
file write fh "Total & `t1' & & `t2' & \\" _n
file write fh "\midrule" _n
local n1 : display %12.0fc `single_mgr'
local n2 : display %12.0fc `firms_all_single'
local p1 : display %5.1f `pct_single_mgr'
local p2 : display %5.1f `pct_firms_all_single'
file write fh "\shortstack{Single-firm CEOs} & \multicolumn{2}{c}{`n1'} & \multicolumn{2}{c}{`p1'\%} \\" _n
file write fh "\shortstack{Firms w/ only\\single-firm CEO} & \multicolumn{2}{c}{`n2'} & \multicolumn{2}{c}{`p2'\%} \\" _n
file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file close fh

*** Some descriptive numbers on firms and ceos
use "../../temp/analysis-sample.dta", clear

keep frame_id_numeric
duplicates drop frame_id_numeric, force
tempfile firm_id
save `firm_id', replace

use "../../temp/manager-firm-facts.dta", clear

merge m:1 frame_id_numeric using `firm_id', nogen keep(matched)

preserve
collapse (count) n_firms = frame_id_numeric, by(person_id)
gen ceo_at2firms = n_firms >= 2
tab ceo_at2firms
tempfile ceo_at2firms
save `ceo_at2firms', replace
restore

merge m:1 person_id using `ceo_at2firms', keep(match) nogen
unique frame_id_numeric if ceo_at2firms
unique frame_id_numeric
