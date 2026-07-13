clear all
use "../../temp/analysis-sample.dta", clear

sort frame_id_numeric year ceo_spell
by frame_id_numeric: gen ceo_switch = ceo_spell - ceo_spell[_n-1]  if _n > 1
replace ceo_switch = 0 if missing(ceo_switch)
gen switch_year = year if ceo_switch

* Step 1: Identify switches and gaps
bysort frame_id_numeric (switch_year): gen switch_gap = switch_year - switch_year[_n-1] if _n > 1

* Step 2: Create clean switches (no other switch within 4 years before or after)
bysort frame_id_numeric (switch_year): gen gap_next = switch_year[_n+1] - switch_year if _n < _N
bysort frame_id_numeric (switch_year): gen gap_prev = switch_year - switch_year[_n-1] if _n > 1

gen clean_switch = (gap_next >= 4 | gap_next == .) & (gap_prev >= 4 | gap_prev == .)

* Step 4: Create switch year for clean switches only
gen switch_year_clean = switch_year if clean_switch == 1
bysort frame_id_numeric: egen switch_year_firm_clean = max(switch_year_clean)

* Step 5: Create relative time
gen time_since_switch = year - switch_year_firm_clean

* Step 6: Note in your paper how many switches were dropped
count if ceo_switch == 1
count if clean_switch == 1 & ceo_switch == 1
keep if clean_switch == 1 | ceo_switch == 0

gen productivity = sales/employment
gen ever_switch = max_ceo_spell>1
egen firm_count = group(frame_id_numeric ever_switch)

* Count distinct firms with vs. without a CEO switch
bysort frame_id_numeric: gen firm_first = (_n==1)
count if firm_first==1 & ever_switch==0
local n_firms_no = r(N)
count if firm_first==1 & ever_switch==1
local n_firms_yes = r(N)
gen n_firm = .

tabstat lnR exporter lnL lnK ROA lnRL n_firm, ///
    by(ever_switch) ///
    statistics(mean) ///
    columns(statistics) ///
    nototal ///
    save

matrix M1 = r(Stat1)
matrix M2 = r(Stat2)

* Overwrite the n_firm column with the real firm counts
matrix M1[1, 5] = `n_firms_no'
matrix M2[1, 5] = `n_firms_yes'

keep if inrange(time_since_switch, -4, 3)
gen before = time_since_switch < 0
gen after = time_since_switch >= 0

collapse lnR exporter lnL lnK ROA lnRL, by(after)

foreach v in lnR exporter lnL lnK ROA lnRL {
    local d_`v' = (`v'[2] - `v'[1])/`v'[1]
}

clear
set obs 1
foreach v in lnR exporter lnL lnK ROA lnRL{
    gen `v' = `d_`v''
}
gen n_firm = .

mkmat lnR exporter lnL lnK ROA lnRL n_firm, matrix(Md)
matrix Combined = M1 \ M2 \ Md
matrix colnames Combined = "lnR" "Exporter" "lnL" "lnK" "ROA" "lnRL" "N"
matrix rownames Combined = "Without CEO Switch" "With CEO Switch" "Change from -4 to 3"

file open tab using "table/switch-descriptives.tex", write replace
file write tab "\begin{tabular}{lccccc}" _n
file write tab "\hline\hline" _n
file write tab " & lnR & Exporter & lnL & lnK & ROA & lnR & N \\" _n
file write tab "\hline" _n

local rownames `""Without CEO Switch" "With CEO Switch" "Change from $ t=-4 $ to $ t=3 $""'

forvalues r = 1/3 {
    local rname : word `r' of `rownames'
    local dec = cond(`r' == 3, 2, 1)
    local line "`rname'"
    forvalues c = 1/5 {
        local val = Combined[`r', `c']
        if missing(`val') {
            local cell ""
        }
        else {
          if `c'!=5 {
            local cell = string(`val', "%5.1f")
            }
          else {
            local cell = string(`val', "%5.0f")
          }
        }
        local line "`line' & $`cell'$"
    }
    file write tab "`line' \\" _n
}

file write tab "\hline\hline" _n
file write tab "\end{tabular}" _n
file close tab
