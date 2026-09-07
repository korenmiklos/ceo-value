---
type: Variable
title: Firm age
description: year minus founding year, capped at 20;the first-year (age 0) is dropped by sample filters.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  46-47,, 56-57 (firm_age,, firm_age_sq)
  - id: filter_code
    resource: ../references/code/filter_do.md
    locator: Line  65 (drop if firm_age < min_firm_age)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
---

# Firm age

## Definition

`firm_age = year - foundyear; replace firm_age =  20 if firm_age > 20 & !missing(firm_age)` (capped at 20;[^var_code] quadratic `firm_age_sq` also built.

## Role

- Sample filter drops firm-age0 rows (incomplete first year).[^filter_code]
- Step function in revenue-function FEs (`local FEs frame_id_numeric firm_age teaor08_2d##year`

.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^filter_code]: [Sample filter code](../references/code/filter_do.md)
