---
type: Result
title: Revenue function estimation
description: Six reghdfe revenue-function models with naive vs debiased R-squared; basis for surplus shares.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: rf_code
    resource: ../references/code/revenue_function_do.md
    locator: Lines  1-55
  - id: r2_table
    resource: ../references/results/table_r2s_full.md
    locator: Full table
relations:
  - predicate: uses_sample
    target: ../sample/network_sample.md
    basis: declared
    qualifiers: model 6 restriction
  - predicate: supported_by
    target: ../claim/debiased_r2_claim.md
    basis: inferred
---

# Revenue function estimation

## Content

Six revenue-function models estimated by reghdfe, appending to temp/revenue_models.ster. Models differ in inputs (log labor, capital, materials, intermediates), fixed effects, and sample restriction (model 6: giant/connected components). The R2s table reports naive and debiased fit, and the residuals feed surplus share computation in the surplus analysis.

## Notes

Referenced controls ceo_age_sq, ceo_tenure, ceo_tenure_sq are not constructed by the traced variables.do, a modeling gap.

[^rf_res]: [Revenue function code](../references/code/revenue_function_do.md).