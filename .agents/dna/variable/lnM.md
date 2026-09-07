---
type: Variable
title: Log materials (lnM)
description: Natural logarithm of materials costs; output in event studies and revenue-function model 4.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line   9 (lnM = ln(materials))
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: materials.md
    basis: inferred
    evidence: [var_code]
---

# Log materials (lnM)

## Definition

`lnM = ln(materials)`.[^var_code]

## Role

- Outcome in revenue-function model 4;and event-study figure 3 ("Materials" panel, application paper`


[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
