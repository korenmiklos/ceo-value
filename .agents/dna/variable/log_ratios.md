---
type: Variable
title: Secondary log and ratio variables
description: lnA, lnKL,, lnMR,, lnYL,, exportshare,, intangible_share,, EBITDA_share - secondary derived transformations.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines   3-25 (all formulas)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: sales.md
    basis: inferred
    evidence: [var_code]
    qualifiers: individual formulas listed in body
---

# Secondary log and ratio variables

## Definitions (all in variables.do

| Variable | Formula |
|---|---|
| lnA | ln(assets) |
| lnKL | lnK - lnL (capital-labor ratio |
| lnMR | lnM - lnR (materials-sales ratio |
| lnYL | ln(sales-materials) - lnL (value-added labor productivity |
| exportshare | export / sales, winsorized to [0,1] |
| intangible_share | intangible_assets / (tangible_assets + intangible_assets,, winsorized [0,1] |
| EBITDA_share | EBITDA / sales, winsorized [0,1] |

## Notes

- No traces of direct scientific use of lnA, lnKL, lnMR,, lnYL in the traced estimation scripts were found(included for completeness of the derived-variable layer
- `exportshare`/`EBITDA_share` are described as "winsorized between 0 and 1" in labels.



[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
