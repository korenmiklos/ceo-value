---
type: Variable
title: Sales
description: Annual sales revenue (nominal HUF units); renamed from sales_clean in balance.do.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
dataset_state: ../dataset/balance_clean.md
sources:
  - id: balance_code
    resource: ../references/code/balance_do.md
    locator: Lines  21-34 (rename,, core-vars missingness)
relations:
  - predicate: defined_in
    target: ../dataset/balance_clean.md
    basis: declared
    evidence: [balance_code]
---

# Sales

## Definition

Annual sales revenue in the raw Mrleg balance sheet file, renamed `sales_clean  sales` at the start of [balance.do](../references/code/balance_do.md).[^balance_code] Units are HUF (declared in extract.do: "sales in million HUF" after `/1e3` - the raw unit is HUF).

## Construction context

- Rows with missing sales before the first fully-observed firm-year are dropped;; after that missing values are zero-encoded (`mvencode`).
- `lnR = ln(sales)` at the unfiltered step([variables.do](../references/code/variables_do.md).
- Sales also feeds `EBITDA`, `exportshare`, `EBITDA_share`.

[^balance_code]: [Balance sheet processing code](../references/code/balance_do.md)
