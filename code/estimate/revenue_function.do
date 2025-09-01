*! version 1.0.0 2025-08-08
* =============================================================================
* Revenue Function Estimation - Issue #14 Specifications
* =============================================================================

clear all

use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

* Define rich controls for models 4-6
local controls lnK foreign_owned has_intangible 
local rich_controls `controls' firm_age firm_age_sq ceo_tenure ceo_tenure_sq ceo_age ceo_age_sq second_ceo third_ceo

* Fixed effects specifications
local FEs frame_id_numeric teaor08_2d##year

eststo clear

eststo model1: reghdfe lnR `controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", replace

eststo model2: reghdfe lnEBITDA `controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model3: reghdfe lnWL `controls', absorb(`FEs') vce(cluster frame_id_numeric) 
estimates save "temp/revenue_models.ster", append

eststo model4: reghdfe lnM `controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model5: reghdfe lnR `rich_controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model6: reghdfe lnR `rich_controls' if component_id == 1, absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

