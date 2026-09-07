---
type: Dataset
title: Manager value per CEO spell
description: First manager skill estimate per firm-CEO-spell, the unit merged into placebo event-study samples for transition comparisons.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mv_code
    resource: ../references/code/manager_value_do.md
    locator: Lines  64-68
relations:
  - predicate: derived_from
    target: ../dataset/manager_value.md
    basis: declared
    evidence: [mv_code]
  - predicate: used_by
    target: ../dataset/placebo_event_study_samples.md
    basis: declared
---

# Manager value per CEO spell

## Construction

After the firm-person-level estimates, [manager_value.do](../references/code/manager_value_do.md) collapses to one row per firm-and-CEO-spell, taking the first value of `manager_skill` per spell The output `temp/manager_value_spell.dta` carries one row per clean CEO spell for the [analysis sample](../dataset/analysis_sample.md) firms.



## Use

[event_study_sample.do](../references/code/event_study_sample_do.md) merges spell skill onto the transition pairs so treated and placebo CEOs are compared on their estimated manager value within event windows.




[^mv_code]: Manager value estimation code - see [manager_value.do](../references/code/manager_value_do.md)
