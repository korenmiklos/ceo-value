---
type: Variable
title: Log tangible assets (lnK)
description: Natural logarithm of tangible assets; the capital input in production/event-study regressions.

status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  4 (lnK = ln(tangible_assets))
  - id: rf_code
    resource: ../references/code/revenue_function_do.md
    locator: Line  14 (lnK control)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: tangible_assets.md
    basis: inferred
    evidence: [var_code]
---

# Log tangible assets (lnK

## Definition

`lnK = ln(tangible_assets)`.[^var_code] Note this uses tangible assets directly (not the derived `capital` variable`

## Role

- Control in revenue-function models (model 1 etc.,[^rf_code].
- Outcome in econometrics event studies (`lnK` ATET and CSV outputs`.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^rf_code]: [Revenue function estimation code](../references/code/revenue_function_do.md)
