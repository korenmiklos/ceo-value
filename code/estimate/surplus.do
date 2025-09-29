* =============================================================================
* SURPLUS ESTIMATION PARAMETERS
* =============================================================================
local min_surplus_share 0          // Minimum surplus share bound
local max_surplus_share 1          // Maximum surplus share bound
local controls lnK has_intangible
local FEs teaor08_2d##year
foreach var in `controls' {
    local diff_controls `diff_controls' D_`var'
}

use "temp/analysis-sample.dta", clear

preserve
    * create lagged variables for instruments
    * this is done separately because there may be multiple observations per year
    keep frame_id_numeric year lnR `controls'
    duplicates drop frame_id_numeric year, force
    xtset frame_id_numeric year
    foreach var of varlist lnR `controls' {
        generate L_`var' = L.`var'
        generate D_`var' = `var' - L_`var'
    }
    keep frame_id_numeric year L_* D_*
    tempfile lags
    save `lags', replace
restore
merge m:1 frame_id_numeric year using `lags', keepusing(L_* D_*) nogenerate

egen spell_begin = min(year), by(frame_id_numeric ceo_spell)
egen first_ever_year = min(year), by(frame_id_numeric)

* build linear prediction of the outcome variable
local predicted 0
foreach var of local controls {
    local predicted `predicted' + _b[D_`var']*`var'
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

    * estimate alpha by GMM, asssuming delta epsilon is orthogonal to capital decided in t-1
    * use only first CEO spell so that manager fixed effect is constant and can be removed by differencing
    * by Olley=Pakes assumptions, capital and intangible assets are decided in t-1. 
    * lag output is correlated with lagged TFP and is a suitable instrument - innovation in TFP is uncorrelated with lagged TFP
    ivreghdfe D_lnR (`diff_controls' = `controls' L_lnR) if sector == `sector' & ceo_spell == 1, absorb(`FEs') vce(cluster frame_id_numeric) 
    quietly replace lnStilde = chi*(lnR - (`predicted')) if sector == `sector'
    foreach var of local controls {
        quietly replace B_`var' = _b[D_`var'] * `var' if sector == `sector'
    }
    drop sector_time
}

keep frame_id_numeric year teaor08_2d sector ceo_spell person_id lnR lnEBITDA lnL lnStilde chi `controls' B_lnK B_has_intangible 
rename lnStilde TFP

* remove sector-year means of TFP
egen st_mean = mean(TFP), by(teaor08_2d year)
replace TFP = TFP - st_mean
drop st_mean

table sector, stat(mean chi)

save "temp/surplus.dta", replace
