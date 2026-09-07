---
type: Reference
title: Manager value estimation code
description: Evidence excerpt from lib/estimate/manager_value.do, manager skill fixed effects.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Manager value estimation code

## Source

- Path: `lib/estimate/manager_value.do`
- SHA-256: `8b80fade63c1bd684b3b6ebf9469c2fc254fcc24d69834ba40e14089d9e19ec3`
- Inspected: exact source slices below

## Excerpts

### Lines 1-11
```text
* =============================================================================
* MANAGER VALUE PARAMETERS
* =============================================================================
local within_firm_skill_min -1     // Minimum within-firm manager skill bound
local within_firm_skill_max 1      // Maximum within-firm manager skill bound  
local outcomes lnR lnEBITDA lnL
local controls lnK foreign_owned has_intangible
local fixed_effect ROA

use "temp/analysis-sample.dta", clear

```

### Lines 24-37
```text
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
```

### Lines 49-62
```text
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
```

### Lines 64-71
```text
* save spell-level version for event study (no person_id needed)
preserve
collapse (firstnm) manager_skill, by(frame_id_numeric ceo_spell)
save "temp/manager_value_spell.dta", replace
restore

collapse (firstnm) firm_fixed_effect manager_skill component_id component_size, by(frame_id_numeric person_id)
save "temp/manager_value.dta", replace
```

## Notes

- `fixed_effect` is ROA (line 8}; manager skill is estimated by a two-way fixed-effects regression of ROA absorbed on firm and person IDs.
- Within-firm skill is demeaned relative to the first CEO's firm-person mean and winsorized to [-1,1] (though the histograms are exported before the winsorization replace, lines 40-45 vs 37}.
- `temp/manager_value.dta` and `temp/manager_value_spell.dta` both exist in the current checkout; `manager_value.log` confirms an observed run of the old naming flow (no variation prefix).
