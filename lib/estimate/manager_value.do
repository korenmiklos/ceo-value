* =============================================================================
* MANAGER VALUE PARAMETERS
* =============================================================================
local within_firm_skill_min -1     // Minimum within-firm manager skill bound
local within_firm_skill_max 1      // Maximum within-firm manager skill bound  
local outcomes lnR lnEBITDA lnL
local controls lnK foreign_owned has_intangible

use "temp/surplus.dta", clear

* Create connected component indicator
do "lib/create/network-sample.do"

egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)

egen within_firm = mean(TFP), by(frame_id_numeric person_id)
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

* now do cross section, but only on connected components

reghdfe TFP, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons

* but across components we cannot make a comparison!
summarize manager_skill if giant_component == 1, detail
replace manager_skill = manager_skill - r(mean)
display "IQR of manager skill: " exp(r(p75) - r(p25))*100 - 100

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

collapse (firstnm) firm_fixed_effect manager_skill chi component_id component_size, by(frame_id_numeric person_id)
save "temp/manager_value.dta", replace