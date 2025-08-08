*! version 1.0.0 2025-08-08
* =============================================================================
* Revenue Function Estimation - Issue #14 Specifications
* =============================================================================

clear all

use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

* Define rich controls for models 4-6
local rich_controls lnK intangible_share foreign_owned firm_age firm_age_sq ceo_tenure ceo_tenure_sq

* Fixed effects specifications
local FEs frame_id_numeric##ceo_spell teaor08_2d##year

eststo clear

* Model 1: Log revenue ~ log assets (baseline)
eststo model1: reghdfe lnR lnK, absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", replace

* Model 2: Log EBITDA ~ log assets  
eststo model2: reghdfe lnEBITDA lnK, absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

* Model 3: Log employment ~ log assets
eststo model3: reghdfe lnL lnK, absorb(`FEs') vce(cluster frame_id_numeric) 
estimates save "temp/revenue_models.ster", append

* Model 4: Log revenue ~ log assets + rich controls
eststo model4: reghdfe lnR `rich_controls', absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

* Model 5: Log revenue ~ log assets + rich controls (1st CEO spell only)
eststo model5: reghdfe lnR `rich_controls' if ceo_spell == 1, absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

* Model 6: Log revenue ~ log assets + rich controls (largest connected component)
eststo model6: reghdfe lnR `rich_controls' if component_id == 1, absorb(`FEs') vce(cluster frame_id_numeric)
estimates save "temp/revenue_models.ster", append

