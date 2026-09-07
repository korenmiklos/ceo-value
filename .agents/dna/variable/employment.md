---
type: Variable
title: Employment
description: Headcount (integer);incremented by 1 in balance.do before log use.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/balance_clean.md
sources:
  - id: balance_code
    resource: ../references/code/balance_do.md
    locator: Lines  21-34,, 58-59 (rename,, +1,, int)
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  8 (lnL = ln(employment))
relations:
  - predicate: defined_in
    target: ../dataset/balance_clean.md
    basis: declared
    evidence: [balance_code]
  - predicate: computed_from
    target: ../data_source/merleg_lts.md
    basis: declared
    evidence: [balance_code]
---

# Employment

## Definition

Employment headcount, renamed `emp  employment` in balance.do.[^balance_code] `employment = employment + 1; employment = int(employment)` before logs - a +1 adjustment to make logs defined at zero.[^balance_code]

## Uses

- `lnL = ln(employment)` (labor input`.[^var_code]
- `max_employment = max(employment)` by firm drives the 3 employee sample filter and size bins (`size1`-`size4`, `max_size`).
- Unit: persons (declared; not unit-verified against raw metadata`.

[^balance_code]: [Balance sheet processing code](../references/code/balance_do.md)
[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
