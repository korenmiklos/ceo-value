---
type: Reference
title: Revenue function estimation code
description: Evidence excerpt from lib/estimate/revenue_function.do, surplus/revenue function models.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Revenue function estimation code

## Source

- Path: `lib/estimate/revenue_function.do`
- SHA-256: `a0b03a7987516c99f4ff3847137313fd01433fbd264ef0388f65cbdcb1a0dc8a`
- Inspected: exact source slices below

## Excerpts

### Lines 8-20
```text
use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "lib/create/network-sample.do"

* Define rich controls for models 4-6
local controls lnK has_intangible foreign_owned state_owned founder owner
local rich_controls `controls' ceo_age ceo_age_sq ceo_tenure ceo_tenure_sq

* Fixed effects specifications
local FEs frame_id_numeric firm_age teaor08_2d##year
local rich_FEs frame_id_numeric##ceo_spell firm_age teaor08_2d##year

```

### Lines 23-39
```text
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
```

## Notes

- Models 1-4: outcome lnR, lnEBITDA, lnWL,, lnM with firm-age step and industry-year FEs; Models 5-6 add CEO-age/tenure quadratics and CEO-spell FE (model 6 restricted to connected components}.
- Note variables `ceo_age_sq`, `ceo_tenure`, `ceo_tenure_sq` referenced here are NOT constructed in lib/util/variables.do (which builds only `firm_age_sq`}; their construction is not traced in this checkout  a code-level gap.
- While `temp/revenue_models.ster` exists in temp,, no root log for revenue_function.do was found in the checkout. Cleanup: cross-check required.
