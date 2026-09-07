---
type: Variable
title: Sales per worker (lnRL)
description: Log sales minus log employment; a labor productivity measure.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/unfiltered.md
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  12 (lnRL = lnR - lnL)
relations:
  - predicate: defined_in
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [var_code]
  - predicate: computed_from
    target: lnR.md
    basis: inferred
    evidence: [var_code]
  - predicate: computed_from
    target: lnL.md
    basis: inferred
    evidence: [var_code]
---

# Sales per worker (lnRL)



Attention: the variable used in the papers is "labor productivity" - indexed by `lnRL` (log sales minus log employment[^var_code]  definio: `lnRL = lnR - lnL`. Note the label in variables.do reads "Sales to labor ratio (log)".

## Role

- Outcome in econometrics event studies (`lnRL` ATET tables and r2s_full table`


[^var_code]: [Derived variable construction code](../references/code/variables_do.md)
