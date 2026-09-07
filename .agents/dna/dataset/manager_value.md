---
type: Dataset
title: Manager value estimates (firm-person level)
description: Two-way fixed-effects manager skill estimates from ROA, saved per firm-person pair, used in placebo event-study construction.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mv_code
    resource: ../references/code/manager_value_do.md
    locator: Lines  1-16
  - id: logs
    resource: ../references/logs.md
    locator: manager_value.log (saved manager_value.dta and manager_value_spell.dta
relations:
  - predicate: estimated_from
    target: ../dataset/analysis_sample.md
    basis: declared
    evidence: [mv_code]
  - predicate: used_by
    target: ../dataset/manager_value_spell.md
    basis: declared
  - predicate: used_by
    target: ../dataset/placebo_event_study_samples.md
    basis: declared
---

# Manager value estimates

## Estimation

`lib/estimate/manager_value.do` estimates a two-way fixed-effects model with manager skill as the `fixed_effect` on `ROA` per firm-person year, isolating manager quality from firm effects. The `fixed_effect` parameter takes `ROA` (not other outcomes), per the [code excerpt](../references/code/manager_value_do.md)।

The estimator writes `temp/manager_value.dta` with firm-person-level estimates including the manager fixed effect, manager-year observations, and spell means downstream merging.





## Use

- Collapsed per CEO spell into [manager_value_spell](../dataset/manager_value_spell.md).
- Merged into placebo event-study samples as the skill measure for treated and placebo CEOs, per [event_study_sample.do](../references/code/event_study_sample_do.md).



[^mv_code]: Manager value estimation code - see [manager_value.do](../references/code/manager_value_do.md)
[^logs]: Stata execution logs - see [logs](../references/logs.md)
