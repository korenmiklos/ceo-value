* =============================================================================
* BALANCE SHEET DATA PARAMETERS
* =============================================================================
local start_year 1992             // Start year for data inclusion
local end_year 2023               // End year for data inclusion

use "input/merleg-LTS-2024/balance/balance_sheet_80_23.dta", clear

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

* return on assets, but also defined, if L. is missing, assuming EBITDA increased assets
* this has to be done on the firm panel so that xtset is unambiguous
xtset frame_id_numeric year
generate EBITDA = sales - personnel_expenses - materials
generate capital = cond(missing(L.assets), assets - EBITDA, L.assets)

compress
save "temp/balance.dta", replace
