use "../../temp/unfiltered.dta", clear

preserve
collapse (count) n_ceos = person_id, by(frame_id_numeric year)
replace n_ceos = 5 if n_ceos>4
tab n_ceos, matcell(freq1)
local N1 = r(N)
restore

egen firm_ceo_tag = tag(frame_id_numeric person_id)
collapse (sum) n_ceos = firm_ceo_tag, by(frame_id_numeric)
replace n_ceos = 5 if n_ceos>4
tab n_ceos, matcell(freq2)
local N2 = r(N)

file open fh using "table/ceo_counts.tex", write replace
file write fh "\begin{tabular}{*{3}{c}}" _n
file write fh "\toprule" _n
file write fh "CEOs & Firm-years & \% & Firms & \% \\" _n
file write fh "\midrule" _n

forvalues i = 1/5 {
      local label = cond(`i' == 5, "4+", "`=`i'-1'")
      local f1 : display %12.0fc freq1[`i', 1]
      local p1 : display %5.1f 100 * freq1[`i', 1] / `N1'
      local f2 : display %12.0fc freq2[`i', 1]
      local p2 : display %5.1f 100 * freq2[`i', 1] / `N2'
      file write fh "`label' & `f1' & `p1'\% & `f2' & `p2'\% \\" _n
  }

file write fh "\midrule" _n
local t1 : display %12.0fc `N1'
local t2 : display %12.0fc `N2'
file write fh "Total & `t1' & `t2' \\" _n
file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file close fh
