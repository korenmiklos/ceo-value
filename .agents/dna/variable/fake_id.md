---
type: Variable
title: Fake firm identifier
description: Pseudo-firm identifier unifying one treated transition and its placebo control into a single event-study unit.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: ess_code
    resource: ../references/code/event_study_sample_do.md
    locator: Lines  132-147
relations:
  - predicate: defined_in
    target: ../dataset/placebo_event_study_samples.md
    basis: declared
    evidence: [ess_code]
---

# Fake firm identifier

## Definition

`fake_id` identifies the pseudo-firm formed by one treated transition and its matched placebo control, giving each event-time observation a panel unit within which treated and placebo arms are compared. T1 and T2 define the event-time window bounds around the change year.

[^ess_code]: [Placebo event study sample construction code](../references/code/event_study_sample_do.md).