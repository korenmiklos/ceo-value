---
type: Result
title: Average treatment effect on the treated, replacement on firm outcomes
description: "ATET estimates from the application paper table 2: 0.005, 0.001, 0.003 on growth, employment, capital, sales outcomes."
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: app_table
    resource: ../references/results/table2_result.md
    locator: Full table
  - id: app_paper
    resource: ../references/paper_application.md
    locator: "Table 2 section"
relations:
  - predicate: uses_sample
    target: ../sample/placebo_event_study_sample.md
    basis: declared
  - predicate: supported_by
    target: ../claim/atet_estimates.md
    basis: inferred
---

# ATET estimates (Table 2)

## Values

Event-study ATET of CEO replacement on firm outcomes per application paper table 2:

- Growth: 0.005, significance at 0.1%.
- Assets: 0.001, 0.1% significant.
- Capital (alternative): 0.003.
- Observations in the estimation sample: 3,361,459 and related counts.
- Standard errors clustered by firm.

## Notes

Reproduction status: the table-2 estimates match the numbers in the paper draft; the producing event-study do files exist but the exact replication run was not re-executed in this build (Stata code traced, not run).

[^app_table]: [Table 2 result reference](../references/results/table2_result.md).
