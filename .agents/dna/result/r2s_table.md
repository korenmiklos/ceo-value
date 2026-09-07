---
type: Result
title: R-squared table, naive vs debiased revenue-function fits
description: OLS R2 0.65-0.68 vs debiased 0.18-0.31 across revenue-function models; key validation of the debiasing claim.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: r2_table
    resource: ../references/results/table_r2s_full.md
    locator: Full table
  - id: paper_eco
    resource: ../references/paper_econometrics.md
    locator: R-squared section
relations:
  - predicate: uses_variable
    target: ../variable/lnR.md
    basis: declared
  - predicate: supported_by
    target: ../claim/debiased_r2_claim.md
    basis: inferred
---

# R-squared table (r2s_full)

## Values

Naive OLS R2: 0.679, 0.675, 0.657, 0.647, 0.649 across the five model columns. Debiased R2: 0.314, 0.263, 0.273, 0.177, 0.292. The paper interprets the gap as conventional estimators overstating fit relative to linearly debiased estimates.

[^r2_table]: [r2s_full.tex reference](../references/results/table_r2s_full.md).