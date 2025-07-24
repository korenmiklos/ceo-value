use "temp/analysis-sample.dta", clear

local FEs frame_id_numeric##ceo_spell sector_time=teaor08_2d##year
local controls lnK intangible_share foreign_owned state_owned

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

    reghdfe lnR `controls' if sector == `sector', absorb(`FEs') vce(cluster frame_id_numeric) residuals keepsingletons
    quietly replace lnStilde = chi*(lnR - (`predicted') - sector_time) if sector == `sector'
    drop sector_time
}

keep frame_id_numeric year teaor08_2d sector ceo_spell person_id lnR lnEBITDA lnL lnStilde chi

table sector, stat(mean chi)

save "temp/surplus.dta", replace
