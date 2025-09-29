clear all
* Define rich controls for models 4-6
local outcomes lnR lnEBITDA lnWL lnM
local controls lnK has_intangible 
local rich_controls `controls' ceo_age ceo_age_sq ceo_tenure ceo_tenure_sq
foreach var in `controls' {
    local diff_controls `diff_controls' D_`var'
}
foreach var in `rich_controls' {
    local diff_rich_controls `diff_rich_controls' D_`var'
}
local sample ceo_spell == 1

* Fixed effects specifications
local FEs firm_age teaor08_2d##year
local rich_FEs `FEs' foreign_owned state_owned

use "temp/analysis-sample.dta", clear
preserve
    * create lagged variables for instruments
    * this is done separately because there may be multiple observations per year
    keep frame_id_numeric year `outcomes' `rich_controls'
    duplicates drop frame_id_numeric year, force
    xtset frame_id_numeric year
    foreach var of varlist `outcomes' `rich_controls' {
        generate L_`var' = L.`var'
        generate D_`var' = `var' - L_`var'
    }
    keep frame_id_numeric year L_* D_*
    tempfile lags
    save `lags', replace
restore
merge m:1 frame_id_numeric year using `lags', keepusing(L_* D_*) nogenerate

* Create connected component indicator
do "code/create/network-sample.do"

eststo clear

eststo model1: ivreghdfe D_lnR (`diff_controls' = L_lnR `controls') if `sample', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", replace

eststo model2: ivreghdfe D_lnEBITDA (`diff_controls' = L_lnR `controls') if `sample', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model3: ivreghdfe D_lnWL (`diff_controls' = L_lnR `controls') if `sample', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model4: ivreghdfe D_lnM (`diff_controls' = L_lnR `controls') if `sample', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model5: ivreghdfe lnR (`diff_rich_controls' = L_lnR `rich_controls') if `sample', absorb(`rich_FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model6: ivreghdfe lnR (`diff_rich_controls' = L_lnR `rich_controls') if `sample' & ((giant_component == 1 | connected_components == 1)), absorb(`rich_FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

