---
type: Sample
title: Monte Carlo placebo sample
status: draft
description: Simulated placebo panels from lib/create/montecarlo.do and papers/econometrics/src/montecarlo, benchmarking the placebo design under a known null.
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
  - predicate: selected_from
    target: ../dataset/montecarlo_placebo.md
    basis: declared
    evidence: [mc_code]
  - predicate: used_by
    target: ../result/montecarlo_results.md
    basis: inferred
---

# Monte Carlo placebo sample

## Definition

Simulated event-study panels: 10,000 CEO changes with hazard rates per the commented contract, fields frame_id_numeric, year, TFP, ceo_skill. Paper-specific scenario does run under the econometrics Makefile and produce Monte Carlo placebo datasets under papers/econometrics/data.

## Role

Benchmark: the placebo matching design should recover zero average effect under the null on simulated data where the DGP is known.

[^mc_code]: [Monte Carlo generator code](../references/code/montecarlo_do.md).