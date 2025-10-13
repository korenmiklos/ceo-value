*! version 1.0.0 2025-08-08
* =============================================================================
* Revenue Function Estimation - Issue #14 Specifications
* =============================================================================

clear all

use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "lib/create/network-sample.do"

* Define rich controls for models 4-6
local controls lnK has_intangible foreign_owned state_owned founder owner
local rich_controls `controls' ceo_age ceo_age_sq ceo_tenure ceo_tenure_sq

* Fixed effects specifications
local FEs frame_id_numeric firm_age teaor08_2d##year
local rich_FEs frame_id_numeric##ceo_spell firm_age teaor08_2d##year

eststo clear

eststo model1: reghdfe lnR `controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", replace

eststo model2: reghdfe lnEBITDA `controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model3: reghdfe lnWL `controls', absorb(`FEs') vce(cluster frame_id_numeric) 
estimates save "temp/revenue_models.ster", append

eststo model4: reghdfe lnM `controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model5: reghdfe lnR `rich_controls', absorb(`rich_FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

eststo model6: reghdfe lnR `rich_controls' if (giant_component == 1) | (connected_components == 1), absorb(`rich_FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

