---
type: Variable
title: Capital stock
description: Capital proxy; lagged total assets when available, else assets minus EBITDA.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/balance_clean.md
sources:
  - id: balance_code
    resource: ../references/code/balance_do.md
    locator: Line  65 (capital formula)
relations:
  - predicate: defined_in
    target: ../dataset/balance_clean.md
    basis: declared
    evidence: [balance_code]
  - predicate: computed_from
    target: assets.md
    basis: inferred
    evidence: [balance_code]
    qualifiers: lagged assets, else assets - EBITDA
  - predicate: computed_from
    target: ebitda.md
    basis: inferred
    evidence: [balance_code]
---

# Capital stock

## Definition

`generate capital = cond(missing(L.assets), assets - EBITDA, L.assets)` - hoed: lagged total assets when available, otherwise current assets minus EBITDA.[^balance_code]

## Uses

- `lnK = ln(tangible_assets)` is the log capital input used in regressions (not this `capital` variable; note the distinction: `lnK` uses tangible assets directly)
- This `capital` variable itself is not referenced downstream in traced scripts (constructed butunused subsequently - a dormant intermediate`



[^balance_code]: [Balance sheet processing code](../references/code/balance_do.md)
