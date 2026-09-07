---
type: Result
title: Surplus shares by industry, Table A3
description: Surplus shares 0.064-0.188 across industries from the application appendix.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: app_table
    resource: ../references/results/tableA3_result.md
    locator: Full table
  - id: make_app
    resource: ../references/makefile_application.md
    locator: surplus_analysis rule
relations:
  - predicate: uses_sample
    target: ../dataset/surplus.md
    basis: declared
  - predicate: supported_by
    target: ../claim/surplus_shares_claim.md
    basis: inferred
---

# Surplus shares by industry (Table A3)

## Values

Estimated surplus shares by industry in the range 0.064 to 0.188, from the application paper's surplus analysis consuming temp/surplus.dta. The producing script surplus.do is missing from the checkout; the result table file itself exists and is referenced from the appendix.

[^res/tableA3]: [Table A3 reference](../references/results/tableA3_result.md).