use "input/merleg-LTS-2023/balance/balance_sheet_80_22.dta", clear

keep if inrange(year, 1992, 2022)
drop if frame_id == "only_originalid"
generate long frame_id_numeric = real(substr(frame_id, 3, .)) if substr(frame_id, 1, 2) == "ft"

tabulate year, missing

local dimensions frame_id_numeric originalid foundyear year teaor08_2d teaor08_1d
local facts sales export emp tanass ranyag wbill persexp immat so3_with_mo3 fo3

keep `dimensions' `facts'
order `dimensions' `facts'

rename emp employment
rename tanass tangible_assets
rename ranyag materials
rename wbill wagebill
rename persexp personnel_expenses
rename immat intangible_assets
rename so3_with_mo3 state_owned
rename fo3 foreign_owned

mvencode sales export employment tangible_assets materials wagebill personnel_expenses intangible_assets state_owned foreign_owned, mv(0) override
replace employment = 1 if employment < 1

compress

save "temp/balance.dta", replace