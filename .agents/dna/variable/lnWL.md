---
type: Variable
title: Average wage per worker (lnWL)
description: Log wagebill minus log employment; a wage-per-worker measure.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  9 (lnWL = ln(wagebill) - lnL)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: wagebill.md
    basis: inferred
    evidence: [var_code]
  - predicate: computed_from
    target: lnL.md
    basis: inferred
    evidence: [var_code]
---

# Average wage per worker (lnWL

## Definition

`lnWL = ln(wagebill) - lnL` - log wagebill minus log employment (a per-worker wage measure).[^var_code]

## Role

- Outcome in revenue-function model 3 and event-study figure  3 ("Wagebill" panel, application paper) and ATET tables (lnWL outputs`.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
