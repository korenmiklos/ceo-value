* =============================================================================
* BALANCE SHEET DATA PARAMETERS
* =============================================================================
local start_year 1992             // Start year for data inclusion
local end_year 2022               // End year for data inclusion
local min_employment 1            // Minimum employment threshold

use "input/merleg-LTS-2023-patch/balance/balance_sheet_80_22.dta", clear

keep if inrange(year, `start_year', `end_year')
drop if frame_id == "only_originalid"
generate long frame_id_numeric = real(substr(frame_id, 3, .)) if substr(frame_id, 1, 2) == "ft"

egen double ranyag_fill = rowtotal(ranyag01 ranyag02 ranyag03 ranyag04 ranyagesz) 
replace ranyag = ranyag_fill if ranyag==. & ranyag_fill!=. & ranyag_fill!=0

for any gdp gdp22: cap drop X

egen double x = rowtotal(sales aktivalt)
gen double gdp = x - ranyag

foreach x in gdp ranyag immat_clean tanass_clean {
 cap drop `x'22
  gen double `x'22=`x'/ppi22
		}
		
* GDP before 1992 is in balance-sheet-1980-2022-panel-cleaned/output/panel1980_2022_2.dta		
*replace gdp = gdp_orig if year<=1991

tabulate year, missing

local dimensions frame_id_numeric originalid foundyear year teaor08_2d teaor08_1d
local facts sales22 export22 emp tanass_clean22 ranyag22 wbill22 persexp22 immat_clean22 so3_with_mo3 fo3

keep `dimensions' `facts'
order `dimensions' `facts'

rename emp employment
rename tanass_clean22 tangible_assets
rename ranyag22 materials
rename wbill22 wagebill
rename persexp22 personnel_expenses
rename immat_clean22 intangible_assets
rename so3_with_mo3 state_owned
rename fo3 foreign_owned

mvencode sales22 export22 employment tangible_assets materials wagebill personnel_expenses intangible_assets state_owned foreign_owned, mv(0) override
replace employment = `min_employment' if employment < `min_employment'

compress

save "temp/balance.dta", replace
