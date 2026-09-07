---
type: Claim
title: Conventional estimators overstate revenue-function fit
description: Naive OLS R2 0.65-0.68 vs linearly debiased 0.18-0.31 in the econometrics paper.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: paper_eco
    resource: ../references/paper_econometrics.md
    locator: Lines 1000-1030
  - id: r2_table
    resource: ../references/results/table_r2s_full.md
    locator: Full table
relations:
  - predicate: supported_by
    target: ../result/r2s_table.md
    basis: declared
    evidence: [r2_table]
---

# Conventional estimators overstate revenue-function fit

## Claim

The June 2026 econometrics paper claims conventional estimators overstate the revenue function's explanatory power: OLS R2 around 0.65-0.68 falls to 0.18-0.31 once estimates are linearly debiased, implying much of the apparent fit reflects estimation noise in the fixed effects.

## Evidence

r2s_full.tex reports naive 0.679, 0.675, 0.657, 0.647, 0.649 and debiased 0.314, 0.263, 0.273, 0.177, 0.292 across the five columns.

## Notes

README-era numbers (25.3/19.7/5.5 percent) disagree with current paper values; recorded as a package-level discrepancy.