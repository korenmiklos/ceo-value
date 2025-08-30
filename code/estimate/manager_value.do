* =============================================================================
* MANAGER VALUE PARAMETERS
* =============================================================================
local within_firm_skill_min -1     // Minimum within-firm manager skill bound
local within_firm_skill_max 1      // Maximum within-firm manager skill bound  
local connected_skill_min -2       // Minimum connected component skill bound
local connected_skill_max 2        // Maximum connected component skill bound
local largest_component_id 1       // ID of largest connected component

use "temp/surplus.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)

egen within_firm = mean(lnStilde), by(frame_id_numeric person_id)
egen first_ceo = mean(cond(ceo_spell == 1, within_firm, .)), by(frame_id_numeric)
replace within_firm = within_firm - first_ceo
drop first_ceo

* convert manager skill to revenue/surplus contribution
summarize within_firm if ceo_spell > 1, detail
display "IQR of within-firm variation in manager skill: " exp(r(p75) - r(p25))*100 - 100
replace within_firm = . if !inrange(within_firm, `within_firm_skill_min', `within_firm_skill_max')

* Create histogram for within-firm manager skill variation
histogram within_firm if ceo_spell > 1, ///
    title("Panel A: Within-firm Manager Skill Distribution") ///
    xtitle("Manager Skill (log points)") ///
    ytitle("Density") ///
    normal
graph export "output/figure/manager_skill_within.pdf", replace

generate within_firm_chi = within_firm / chi
summarize within_firm_chi if ceo_spell > 1, detail
display "IQR of within-firm variation in manager surplus: " exp(r(p75) - r(p25))*100 - 100

local outcomes lnR lnEBITDA lnL
local controls lnK foreign_owned has_intangible
frame create within_firm strL outcome strL control contribution
foreach outcome of local outcomes {
    display "Explaining within-firm variation in `outcome'..."
    reghdfe within_firm_chi `outcome' if max_ceo_spell > 1, absorb(frame_id_numeric teaor08_2d##year) vce(cluster frame_id_numeric)
    scalar `outcome'_manager = _b[`outcome'] * 100
    frame post within_firm ("`outcome'") ("manager") (`outcome'_manager) 
    scalar total_explained = `outcome'_manager
    foreach var of local controls {
        reghdfe B_`var' `outcome' if max_ceo_spell > 1, absorb(frame_id_numeric teaor08_2d##year) vce(cluster frame_id_numeric)
        scalar `outcome'_`var' = _b[`outcome'] * 100
        frame post within_firm ("`outcome'") ("`var'") (`outcome'_`var')
        scalar total_explained = total_explained + `outcome'_`var'
    }
    scalar `outcome'_residual = 100 - total_explained
    frame post within_firm ("`outcome'") ("residual") (`outcome'_residual)
}
drop within_firm_chi
scalar list

frame within_firm: save "temp/within_firm.dta", replace

* now do cross section, but only on connected components
keep if component_id == `largest_component_id'

reghdfe lnStilde, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons

summarize manager_skill, detail
replace manager_skill = manager_skill - r(mean)
display "IQR of manager skill: " exp(r(p75) - r(p25))*100 - 100
replace manager_skill = . if !inrange(manager_skill, `connected_skill_min', `connected_skill_max')

* Create histogram for connected component manager skill distribution
histogram manager_skill, ///
    title("Panel B: Connected Component Manager Skill Distribution") ///
    xtitle("Manager Skill (log points)") ///
    ytitle("Density") ///
    normal
graph export "output/figure/manager_skill_connected.pdf", replace

generate manager_skill_chi = manager_skill / chi
generate firm_fixed_effect_chi = firm_fixed_effect / chi
summarize manager_skill_chi, detail
display "IQR of manager surplus: " exp(r(p75) - r(p25))*100 - 100

* Create regression table for manager skill effects
local outcomes lnR lnEBITDA lnL
local controls lnK foreign_owned has_intangible
frame create cross_section strL outcome strL control contribution
foreach outcome of local outcomes {
    display "Explaining cross-sectional variation in `outcome'..."

    reghdfe manager_skill_chi `outcome', absorb(teaor08_2d##year) vce(cluster frame_id_numeric)
    scalar `outcome'_manager = _b[`outcome'] * 100
    frame post cross_section ("`outcome'") ("manager") (`outcome'_manager) 
    scalar total_explained = `outcome'_manager

    reghdfe firm_fixed_effect_chi `outcome', absorb(teaor08_2d##year) vce(cluster frame_id_numeric)
    scalar `outcome'_firm = _b[`outcome'] * 100
    frame post cross_section ("`outcome'") ("firm") (`outcome'_firm) 

    foreach var of local controls {
        reghdfe B_`var' `outcome', absorb(teaor08_2d##year) vce(cluster frame_id_numeric)
        scalar `outcome'_`var' = _b[`outcome'] * 100
        frame post cross_section ("`outcome'") ("`var'") (`outcome'_`var')
        scalar total_explained = total_explained + `outcome'_`var'
    }
    scalar `outcome'_residual = 100 - total_explained
    frame post cross_section ("`outcome'") ("residual") (`outcome'_residual)
}
drop manager_skill_chi firm_fixed_effect_chi
scalar list

frame cross_section: save "temp/cross_section.dta", replace

collapse (firstnm) firm_fixed_effect manager_skill chi, by(frame_id_numeric person_id)
save "temp/manager_value.dta", replace