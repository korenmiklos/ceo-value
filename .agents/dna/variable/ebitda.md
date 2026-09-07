---
type: Variable
title: EBITDA
description: Earnings before interest, taxes, depreciation, and amortization; computed as sales minus personnel expenses minus materials.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/balance_clean.md
sources:
  - id: balance_code
    resource: ../references/code/balance_do.md
    locator: Lines  63-64 (EBITDA formula)
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  23,, 26 (lnEBITDA,, EBITDA_share,, ROA uses EBITDA)
relations:
  - predicate: defined_in
    target: ../dataset/balance_clean.md
    basis: declared
    evidence: [balance_code]
  - predicate: computed_from
    target: sales.md
    basis: inferred
    evidence: [balance_code]
    qualifiers: sales - personnel_expenses - materials
  - predicate: computed_from
    target: personnel_expenses.md
    basis: inferred
    evidence: [balance_code]
  - predicate: computed_from
    target: materials.md
    basis: inferred
    evidence: [balance_code]
---

# EBITDA

## Definition

`generate EBITDA = sales - personnel_expenses - materials` in balance.do.[^balance_code] This is the flow-based earnings measure used throughout.

## Uses

- `ROA = EBITDA / ((L.tangible_assets + tangible_assets)/2)...` wait - exact formula: `ROA = EBITDA/(L.tangible_assets + tangible_assets) * 2`.[^var_code]
- `lnEBITDA`, `EBITDA_share = EBITDA/sales`.



[^balance_code]: [Balance sheet processing code](../references/code/balance_do.md)
[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
