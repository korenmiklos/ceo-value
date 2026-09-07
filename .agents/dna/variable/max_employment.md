---
type: Variable
title: Maximum employment
description: Firm-level maximum employment over the observed panel; drives the 3-employee sample filter and size bins.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  22 (egen max_employment)
  - id: filter_code
    resource: ../references/code/filter_do.md
    locator: Lines  72-73 (drop if max_employment < min_employment)
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

# Maximum employment

## Definition

`egen max_employment = max(employment), by(frame_id_numeric)` - firm-level lifetime maximum employment.[^var_code]

## Role

- Sample filter drops firms with `max_employment < 3`.[^filter_code]
- Derives `max_size` (9 vs 10+ employees bins).



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^filter_code]: [Sample filter code](../references/code/filter_do.md)
