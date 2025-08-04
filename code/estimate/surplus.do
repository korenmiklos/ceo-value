use "temp/analysis-sample.dta", clear

* control for firm age as a step function
local knots 3 4 5 10 20 40
local current_knot 2
foreach knot of local knots {
    quietly generate byte A`current_knot' = inrange(firm_age, `current_knot', `knot'-1)
    local current_knot `knot'
}
quietly generate byte A`current_knot' = firm_age >= `current_knot'

egen spell_begin = min(year), by(frame_id_numeric ceo_spell)
egen first_ever_year = min(year), by(frame_id_numeric)
* event time -1 and 0 are noisy, omit these from the estimation
generate byte change_window = inrange(year, spell_begin - 1, spell_begin) & (year > first_ever_year)

local FEs frame_id_numeric##ceo_spell sector_time=teaor08_2d##year
local controls lnK intangible_share foreign_owned A2 A3 A4 A5 A10 A20 A40 ceo_tenure

* build linear prediction of the outcome variable
local predicted 0
foreach var of local controls {
    local predicted `predicted' + _b[`var']*`var'
}

quietly generate double lnStilde = .
quietly generate double chi = .

generate double surplus_share = EBITDA / sales
replace surplus_share = 0 if surplus_share < 0
replace surplus_share = 1 if surplus_share > 1 & !missing(surplus_share)

levelsof sector, local(sectors)
foreach sector of local sectors {
    summarize surplus_share if sector == `sector' [aw=sales], meanonly
    quietly replace chi = r(mean) if sector == `sector'

    reghdfe lnR `controls' change_window if sector == `sector', absorb(`FEs') vce(cluster frame_id_numeric) residuals keepsingletons
    quietly replace lnStilde = chi*(lnR - (`predicted') - sector_time) if sector == `sector'
    drop sector_time
}

keep frame_id_numeric year teaor08_2d sector ceo_spell person_id lnR lnEBITDA lnL lnStilde chi change_window

table sector, stat(mean chi)

save "temp/surplus.dta", replace
