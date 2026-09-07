---
type: Result
title: Monte Carlo simulation results, placebo design
description: Simulated benchmark statistics from the placebo design under a known null; panicle estimates of size/power.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mc_code
    resource: ../references/code/montecarlo_do.md
    locator: Lines  3-114
  - id: mc_src
    resource: ../references/code/montecarlo_do.md
    locator: Scenario does under papers/econometrics/src/montecarlo
relations:
  - predicate: uses_sample
    target: ../sample/montecarlo_sample.md
    basis: declared
    evidence: [mc_code]
  - predicate: supported_by
    target: ../claim/montecarlo_validates_placebo.md
    basis: inferred
---

# Monte Carlo results

## Content

Simulated placebo event-study panels benchmark the design: under a known null (no average effect), the placebo matching should recover zero coefficient; the tables report bias, variance, and rejection rates across 407 CSV results (355 ATET) present in papers/econometrics/data. The exact table numbers were not extracted in this build; the artifact files exist.

## Notes

This result corroborates the paper's placebo-validity claim rather than the main ATET estimates.

[^mc_code]: [Monte Carlo generator code](../references/code/montecarlo_do.md).