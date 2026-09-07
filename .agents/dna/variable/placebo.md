---
type: Variable
title: Placebo indicator
description: Flag distinguishing placebo pseudo-firms from treated transitions in the event-study sample; zero for genuinely observed replacements.
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
    qualifiers: event-window containment; fake_id unifies treated and placebo
---

# Placebo indicator

## Definition

`placebo` distinguishes the counterfactual pseudo-firm arms in the event-study panel: treated rows are genuine CEO replacements, placebo rows are non-transition firms whose uninterrupted CEO spell window contains the event window. The estimator contrasts treated against placebo to difference out common time dynamics.

[^ess_code]: [Placebo event study sample construction code](../references/code/event_study_sample_do.md).