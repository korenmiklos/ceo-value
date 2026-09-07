---
type: Dataset
title: Revenue function estimates (temp/revenue_models.ster)
description: Saved reghdfe estimates of six revenue function models, source for surplus share computation and the revenue function results table.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: rf_code
    resource: ../references/code/revenue_function_do.md
    locator: Lines  1-55
relations:
  - predicate: derived_from
    target: ../dataset/analysis_sample.md
    basis: declared
    evidence: [rf_code]
  - predicate: used_by
    target: ../result/revenue_function_estimation.md
    basis: declared
---

# Revenue function estimates

## Construction

`lib/estimate/revenue_function.do` estimates six revenue function models by reghdfe and appends results to `temp/revenue_models.ster`. The specifications vary inputs and fixed effects:

- Model 1..6 combine log sales outcome with log labor, log capital, log materials, log intermediates, firm fixed effects, year effects, and closeness controls per the [code excerpt](../references/code/revenue_function_do.md).
- Model 6 restricts the sample to giant or connected components per the network flags, see [large component managers](../dataset/large_component_managers.md).



## Notes

- Referenced controls `ceo_age_sq`, `ceo_tenure`, `ceo_tenure_sq` are not constructed by the traced [variables.do](../references/code/variables_do.md), a modeling gap to note.
- The saved estimates feed surplus share computation via `predict` residuals during estimation per the code.



[^rf_code]: Revenue function estimation code - see [revenue_function.do](../references/code/revenue_function_do.md)