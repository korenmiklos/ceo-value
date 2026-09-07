---
type: Sample
title: Placebo event-study sample
description: Pseudo-firm transition panel where treated CEO replacements are matched to placebo non-transition firms on cohort, sector, size and window.
status: [draft]
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: ess_code
    resource: ../references/code/event_study_sample_do.md
    locator: Lines  1-247
relations:
  - predicate: selected_from
    target: ../dataset/placebo_event_study_samples.md
    basis: declared
    evidence: [ess_code]
  - predicate: depends_on
    target: ../variable/fake_id.md
    basis: declared
  - predicate: depends_on
    target: ../variable/placebo.md
    basis: declared
---

# Placebo event-study sample

## Construction

Built by [event_study_sample.do](../references/code/event_study_sample_do.md): treated transitions are consecutive clean CEO spells; controls are non-transition firms drawn with probability proportional to 10 times treated count over control count (seed 1391); placebo change year drawn from the treated t0 distribution; `fake_idd` unifies treated and placebo pseudo-firms into one panel. Full details in the [placebo samples dataset](../dataset/placebo_event_study_samples.md).

## Role in estimation

The placebo arms construct the counterfactual: a pseudo-firm with a CEO change drawn at a time when no genuine transition occurred, so the event-time estimates under the null should be zero.

[^ess_code]: [Placebo event study sample construction code](../references/code/event_study_sample_do.md).