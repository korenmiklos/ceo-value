* =============================================================================
* BALANCE SHEET DATA PARAMETERS
* =============================================================================
local start_year 1992             // Start year for data inclusion
local end_year 2022               // End year for data inclusion

use "input/merleg-LTS-2023/balance/balance_sheet_80_22.dta", clear

keep if inrange(year, `start_year', `end_year')
drop if frame_id == "only_originalid"
generate long frame_id_numeric = real(substr(frame_id, 3, .)) if substr(frame_id, 1, 2) == "ft"

tabulate year, missing

local dimensions frame_id_numeric originalid foundyear year teaor08_2d teaor08_1d so3_with_mo3 fo3
local facts sales_clean export emp eszk tanass ranyag wbill persexp immat 

keep `dimensions' `facts'
order `dimensions' `facts'

rename sales_clean sales
rename emp employment
rename tanass tangible_assets
rename ranyag materials
rename wbill wagebill
rename persexp personnel_expenses
rename immat intangible_assets
rename so3_with_mo3 state_owned
rename fo3 foreign_owned
rename eszk assets


* Drop firm-years with missing core vars.
local core_vars sales employment tangible_assets materials personnel_expenses assets

local N_before = _N
generate byte core_missing = 0
foreach var of local core_vars {
    display "Missing `var': "
    count if missing(`var')
    replace core_missing = 1 if missing(`var')
}
count if core_missing == 1
display "Total firm-years with any missing core variable: " r(N) " out of `N_before'"

* find first year with complete core data for each firm
egen first_clean_year = min(cond(core_missing == 0, year, .)), by(frame_id_numeric)
count if year < first_clean_year
display "Firm-years before first clean year: " r(N)
count if core_missing == 1 & year >= first_clean_year
display "Firm-years with missing core after first clean year: " r(N)

drop if year < first_clean_year | core_missing == 1
display "Dropped " `N_before' - _N " firm-years, " _N " remaining"
drop core_missing first_clean_year

mvencode sales export employment assets tangible_assets materials wagebill personnel_expenses intangible_assets state_owned foreign_owned, mv(0) override
replace employment = employment + 1 
replace employment = int(employment)

preserve

tempfile tax
use "input/balance-sheet-1980-2023-panel-cleaned/panel1980_2023_2.dta",clear
drop if originalid < 0
keep if inrange(year, 1992, 2022)
drop if frame_id == "only_originalid"
ren frame_id2 frame_id_numeric

cap drop tao_ceu
gen double tao_ceu = pretax - eredadoz
replace tao_ceu = . if year < 2006
cap drop tao_final
clonevar tao_final = tao_old
replace tao_final = tao_ceu if tao_ceu != . & year >= 2006
replace tao_final = abs(tao_final)
cap drop tax
ren (tao_final keszl) (tax inventories)
gen double aftertax = pretax - tax
keep frame_id_numeric aftertax inventories year
save `tax', replace
restore
* return on assets, but also defined, if L. is missing, assuming EBITDA increased assets
* this has to be done on the firm panel so that xtset is unambiguous
xtset frame_id_numeric year
generate EBITDA = sales - personnel_expenses - materials
generate L_assets = L.assets
generate L_tangibles = L.tangible_assets
generate L_intangibles = L.intangible_assets
generate capital = cond(missing(L.assets), assets - EBITDA, L.assets)

merge 1:1 frame_id_numeric year using `tax', nogen keep(matched)
* master only 130
* using only 162493
compress
save "temp/balance.dta", replace
