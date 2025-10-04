* =============================================================================
* SURPLUS ESTIMATION PARAMETERS
* =============================================================================
local min_surplus_share 0          // Minimum surplus share bound
local max_surplus_share 1          // Maximum surplus share bound
local controls lnK has_intangible
local FEs frame_id_numeric##ceo_spell sector_time=teaor08_2d##year

use "temp/analysis-sample.dta", clear

egen spell_begin = min(year), by(frame_id_numeric ceo_spell)
egen first_ever_year = min(year), by(frame_id_numeric)

* build linear prediction of the outcome variable
local predicted 0
foreach var of local controls {
    local predicted `predicted' + _b[`var']*`var'
    quietly generate double B_`var' = .
}

quietly generate double lnStilde = .
quietly generate double chi = .

generate double surplus_share = EBITDA / sales
replace surplus_share = `min_surplus_share' if surplus_share < `min_surplus_share'
replace surplus_share = `max_surplus_share' if surplus_share > `max_surplus_share' & !missing(surplus_share)

levelsof sector, local(sectors)
foreach sector of local sectors {
    summarize surplus_share if sector == `sector' [aw=sales], meanonly
    quietly replace chi = r(mean) if sector == `sector'

    reghdfe lnR `controls' if sector == `sector', absorb(`FEs') vce(cluster frame_id_numeric) residuals keepsingletons
    quietly replace lnStilde = chi*(lnR - (`predicted') - sector_time) if sector == `sector'
    foreach var of local controls {
        quietly replace B_`var' = _b[`var'] * `var' if sector == `sector'
    }
    drop sector_time
}

keep frame_id_numeric year teaor08_2d sector ceo_spell person_id lnR lnEBITDA lnL lnStilde chi `controls' B_lnK B_has_intangible 
rename lnStilde TFP

table sector, stat(mean chi)

save "temp/surplus.dta", replace
