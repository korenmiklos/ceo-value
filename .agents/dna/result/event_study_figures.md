---
type: Result
title: Event-study figures, replacement on firm outcomes
description: Estimated event-time coefficients around CEO replacement with placebo bands; treated vs placebo paths.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: es_code
    resource: ../references/code/event_study_do.md
    locator: Full file
  - id: es_setup
    resource: ../references/code/setup_event_study_do.md
    locator: Lines  1-30
relations:
  - predicate: uses_sample
    target: ../sample/placebo_event_study_sample.md
    basis: declared
  - predicate: supported_by
    target: ../claim/event_study_dynamics_claim.md
    basis: inferred
---

# Event-study figures

## Content

Event-study figures plot estimates of the outcome path around CEO replacement: T1 and T2 window bounds, coefficients for treated and placebo pseudo-firms, confidence intervals. Built through the estimator chain event_study.do -> setup_event_study.do -> xt2var.do, with ATET variant via event_study_atet.do.

## Notes

Observed execution of the event-study sample predates current variation-named workflow; one logged run failed with file data/placebo_large.dta not found (r(601)).

[^res_code]: [Event study code](../references/code/event_study_do.md).