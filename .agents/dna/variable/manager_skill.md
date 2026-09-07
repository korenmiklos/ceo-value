---
type: Variable
title: Manager skill
description: Estimated manager quality from a two-way fixed-effects regression of ROA absorbed on firm and person IDs, normalized to the giant-component mean.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mv_code
    resource: ../references/code/manager_value_do.md
    locator: Lines  1-11 and  49-62
relations:
  - predicate: defined_in
    target: ../dataset/manager_value.md
    basis: declared
    evidence: [mv_code]
  - predicate: computed_from
    target: roa.md
    basis: declared
    evidence: [mv_code]
    qualifiers: fixed_effect parameter equals ROA
---

# Manager skill

## Definition

`manager_skill` is the person fixed effect from a two-way fixed-effects regression of ROA (`fixed_effect`) absorbed on `firm_fixed_effect=frame_id_numeric` and `manager_skill=person_id`, estimated in [manager_value.do](../references/code/manager_value_do.md) (lines 1-11, 49-62). It is normalized by subtracting the giant-component mean (`summarize manager_skill if giant_component == 1`, `replace manager_skill = manager_skill - r(mean)`). A within-firm skill measure is also demeaned relative to the first CEO's firm-person mean and winsorized to [-1,1].

## Use

- Collapsed to spell level (first value) in [manager_value_spell](../dataset/manager_value_spell.md) for the event study.
- Extracts further rescale it (component-mean shrink 0.25, chi scaling) in [extract.do](../references/code/extract_do.md); that rescaling is part of the extract analysis, not the estimator itself.
- Histogram panels for connected-component and within-firm skill distributions are exported in the same script.

[^mv_code]: [Manager value estimation code](../references/code/manager_value_do.md).