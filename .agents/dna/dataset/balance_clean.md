---
type: Dataset
title: Balanced sheet cleaning output (temp/balance.dta →
description: Firm-year financial panel after raw balance-sheet cleaning, identifier extraction, employment increment, missing-value zero-encoding, and variable construction inputs.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: bal_code
    resource: ../references/code/balance_do.md
    locator: Lines  1-65
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  1-29
relations:
  - predicate: derived_from
    target: ../data_source/merleg_lts.md
    basis: declared
    evidence: [bal_code]
  - predicate: derived_from
    target: ../data_source/cegjegyzek_lts.md
    basis: declared
    evidence: [bal_code]
    qualifiers: ceo panel merged for firm-person linkage
  - predicate: used_by
    target: ../dataset/unfiltered.md
    basis: inferred
    evidence: [dataset_state]
---

# Balanced sheet cleaning output

## Units and coverage

`temp/balance.dta` is the firm-year panel after the raw balance-sheet file is cleaned. Pipeline steps:

1. Numeric firm IDs extracted from the `"ft"` string prefix in [balance_do.md](../references/code/balance_do.md).
2. Analysis years held to 1992-2022.
3. `employment` incremented by 1 then integer-cast before logs are taken downstream.
br/>4. Missing financial values after the first fully-observed firm-year are zero-encoded per variable. Sales rows before that first year are dropped.
5. Kept-variable set: sales_, export, employment, assets, tangible assets_, materials, wagebill, personnel expenses, intangible assets_, plus ownership flags state_, foreign_, industry codes teaor08_2d, teaor08_1d, and firm-year identifiers.



## Notes

- Variable constructions downstream are documented in [variables_do.md](../references/code/variables_do.md), including logs, ratios, ROA,, EBITDA_share, intangible_share, has_intangible, max_employment.
- `label variable` assignments define human-readable names for the raw codes (e.g. teaor08 codes labeling industries).
- Capital uses lagged assets when available, else assets minus EBITDA, in [capital.md](../variable/capital.md).
- No observation counts were observed for balance.dta in build logs.



[^bal_code]: Balance sheet processing code - see [balance.do](../references/code/balance_do.md)
[^var_code]: Derived variable construction code - see [variables.do](../references/code/variables_do.md)