---
type: Variable
title: Return on assets (ROA)
description: EBITDA over the two-year average of tangible assets, winsorized at p1/p99; fixed-effect variable for manager skill estimation.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  26-29 (ROA formula and winsorization
  - id: mv_code
    resource: ../references/code/manager_value_do.md
    locator: Line  8 (fixed_effect ROA
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: ebitda.md
    basis: inferred
    evidence: [var_code]
    qualifiers: EBITDA / (L.tangible_assets + tangible_assets) * 2
  - predicate: computed_from
    target: tangible_assets.md
    basis: inferred
    evidence: [var_code]
---

# Return on assets (ROA)

## Definition

`generate ROA = EBITDA / (L.tangible_assets + tangible_assets) * 2`. `L.tangible_assets` is the lagged value; the denominator is the sum of lagged and current tangible assets; the trailing `* 2` outside the sum makes the ratio EBITDA over the two-year average of tangible assets. Winsorized at p1/p99 via `replace ROA = . if ROA < r(p1) | (ROA > r(p99) & !missing(ROA))`.[^var_code]

## Role

- The `fixed_effect` parameter in [manager_value.do](../references/code/manager_value_do.md) - manager skill is estimated from ROA in the two-way FE model.[^mv_code]
- Non-missing ROA is required by [filter.do](../references/code/filter_do.md) and the placebo sample building.

[^var_code]: [Derived variable construction code](../references/code/variables_do.md).
[^mv_code]: [Manager value estimation code](../references/code/manager_value_do.md).
