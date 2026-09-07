---
type: Variable
title: Log sales (lnR)
description: Natural logarithm of sales; the revenue outcome in revenue-function and event-study estimations.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  6 (lnR = ln(sales}))
  - id: rf_code
    resource: ../references/code/revenue_function_do.md
    locator: Lines  23,, 35-38 (outcome lnR)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: sales.md
    basis: inferred
    evidence: [var_code]
---

# Log sales (lnR)

## Definition

`lnR = ln(sales)` at the unfiltered step.[^var_code] Sales is zero-encoded and employment +1-adjusted upstream, so `ln` is defined on the transformed series.

## Role

- Outcome in revenue-function models 1,5,6 (and (via surplus share) revenue growth is a CEO-quality metric in the application.), and outcome/quality measure in econometrics-paper event studies (`data/*_lnR-lnR.csv`, ATET tables`.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^rf_code]: [Revenue function estimation code](../references/code/revenue_function_do.md)
