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
egen ever_switch = max(ceo_spell>1), by(frame_id_numeric)

tabstat employment sales productivity ROA, ///
    by(ever_switch) ///
    statistics(mean) ///
    columns(statistics) ///
    nototal ///
    save

matrix M1 = r(Stat1)
matrix M2 = r(Stat2)

keep if inrange(time_since_switch, -4, 3)
gen before = time_since_switch < 0
gen after = time_since_switch >= 0

collapse employment sales productivity ROA, by(after)

foreach v in employment sales productivity ROA {
    local d_`v' = `v'[2] - `v'[1]
}

clear
set obs 1
foreach v in employment sales productivity ROA {
    gen `v' = `d_`v''
}

mkmat employment sales productivity ROA, matrix(Md)
matrix Combined = M1 \ M2 \ Md

matrix colnames Combined = "Avg Employment" "Sales" "Productivity" "ROA"
matrix rownames Combined = "Non-switchers" "Switchers" "Change from -4 to 3"

esttab matrix(Combined) using "table/switch-descriptives.tex", replace ///
        noobs nonumber nomtitle ///
        title("Performance of Firms by CEO switch")
