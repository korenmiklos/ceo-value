---
type: Variable
title: Export revenue
description: Export revenue (HUF); fed into exporter dummy and export share; non-missing export required by sample filter.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/balance_clean.md
sources:
  - id: balance_code
    resource: ../references/code/balance_do.md
    locator: Lines  15-16,, 34 (kept,, core var,, zero-encoding)
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  1,, 15-17 (exporter,, exportshare)
  - id: filter_code
    resource: ../references/code/filter_do.md
    locator: Line  82 (drop if missing(export))
relations:
  - predicate: defined_in
    target: ../dataset/balance_clean.md
    basis: declared
    evidence: [balance_code]
---

# Export revenue

## Definition

Export revenue chip (units HUF; declared), kept as a core fact in balance.do and zero-encoded after first clean year.[^balance_code]

## Uses

- `exporter = export > 0 & !missing(export)`.
- `exportshare = export / sales`, winsorized to [0,1].
- Missing `export` triggers sample drop fired in filter.do.[^filter_code]

[^balance_code]: [Balance sheet processing code](../references/code/balance_do.md)
[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
[^filter_code]: [Sample filter code](../references/code/filter_do.md)
