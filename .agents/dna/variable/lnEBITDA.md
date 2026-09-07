---
type: Variable
title: Log EBITDA (lnEBITDA)
description: Natural logarithm of EBITDA; outcome in revenue-function model  2.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line   7 (lnEBITDA = ln(EBITDA))
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: ebitda.md
    basis: inferred
    evidence: [var_code]
---

# Log EBITDA (lnEBITDA

## Definition

`lnEBITDA = ln(EBITDA)` - log of the flow EBITDA measure.[^var_code]

## Role

Outcome in revenue-function model  2 (`eststo model2: reghdfe lnEBITDA ...`.[^rf_code]

[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^rf_code]: [Revenue function estimation code](../references/code/revenue_function_do.md)
