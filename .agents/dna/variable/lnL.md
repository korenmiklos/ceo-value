---
type: Variable
title: Log employment (lnL)
description: Natural logarithm of the employment measure (already +1-adjusted in balance.do).
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  8 (lnL = ln(employment))
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: employment.md
    basis: inferred
    evidence: [var_code]
---

# Log employment (lnL)

## Definition

`lnL = ln(employment)` - log of the +1-adjusted employment series.[^var_code]

## Role

Labor input in revenue-function model 3 (`lnWL` outcome uses it as the denominator? - lnWL = ln(wagebill - lnL`), and an outcome in econometrics event studies (`lnL` ATET tables`.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
