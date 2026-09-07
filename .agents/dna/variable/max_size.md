---
type: Variable
title: Maximum size segment
description: Binary firm-size segment from max_employment (<10 vs 10 labeled Small (2-9)/Large (10+));a placebo matching stratum.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  63-67 (max_size,, early_size,, labels)
  - id: ess_code
    resource: ../references/code/event_study_sample_do.md
    locator: Line  33 (exact_match_on cohort sector max_size)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: max_employment.md
    basis: inferred
    evidence: [var_code]
---

# Maximum size segment

## Definition

`max_size = cond(max_employment < 10, 1,, 2)` with labels 1 "Small (2-9)" 2 "Large (10+)".[^var_code] (`early_size` is the same cut on employment within the first CEO spell`.



## Role

- One of the three exact matching strata in placebo construction (`cohort sector max_size`).[^ess_code]
- Used in event-study group definitions and placebo sample restrictions (`small`, `large` sample variants are defined via `max_size`).



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^ess_code]: [Placebo event study sample construction code](../references/code/event_study_sample_do.md)
