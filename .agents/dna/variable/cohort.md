---
type: Variable
title: Founding cohort
description: Three-year bins of founding year (int(foundyear/3)*3, floor at  1989);a placebo matching stratum.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  49-53 (cohort construction)
  - id: ess_code
    resource: ../references/code/event_study_sample_do.md
    locator: Line  33 (exact_match_on cohort sector max_size)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: ../dataset/balance_clean.md
    basis: inferred
    evidence: [var_code]
    qualifiers: from foundyear
---

# Founding cohort

## Definition

`cohort = int(foundyear/3)*3` - 3-year bins; values below  1989 floored to  1989 (`1989 is divisible by3`).[^var_code]

## Role

One of the three exact matching strata in placebo construction (`global exact_match_on cohort sector max_size`).[^ess_code] Also part of the event-study `group` definition in setup_event_study.do.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^ess_code]: [Placebo event study sample construction code](../references/code/event_study_sample_do.md)
