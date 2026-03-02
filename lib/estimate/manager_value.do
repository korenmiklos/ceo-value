* =============================================================================
* MANAGER VALUE PARAMETERS
* =============================================================================
local within_firm_skill_min -1     // Minimum within-firm manager skill bound
local within_firm_skill_max 1      // Maximum within-firm manager skill bound  
local outcomes lnR lnEBITDA lnL
local controls lnK foreign_owned has_intangible
local fixed_effect ROA

use "temp/analysis-sample.dta", clear

* person_id lives in intervals.dta, not in the firm-year panel
preserve
use "temp/intervals.dta", clear
generate T = end_year - start_year + 1
expand T
bysort frame_id_numeric person_id spell: generate year = start_year + _n - 1
keep frame_id_numeric person_id year
duplicates drop
tempfile ceo_person_year
save "`ceo_person_year'", replace
restore

joinby frame_id_numeric year using "`ceo_person_year'"

* Create connected component indicator
do "lib/create/network-sample.do"

egen within_firm = mean(`fixed_effect'), by(frame_id_numeric person_id)
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

* now do cross section, but only on connected components

reghdfe `fixed_effect', absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons

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

* save spell-level version for event study (no person_id needed)
preserve
collapse (firstnm) manager_skill, by(frame_id_numeric ceo_spell)
save "temp/manager_value_spell.dta", replace
restore

collapse (firstnm) firm_fixed_effect manager_skill component_id component_size, by(frame_id_numeric person_id)
save "temp/manager_value.dta", replace
