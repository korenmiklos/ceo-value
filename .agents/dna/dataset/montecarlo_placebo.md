---
type: Dataset
title: Monte Carlo placebo panels
description: Simulation-generated placebo event-study panels used to benchmark the placebo design against known DGP parameters.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mc_code
    resource: ../references/code/montecarlo_do.md
    locator: Lines  3-114
  - id: make_eco
    resource: ../references/makefile_econometrics.md
    locator: Monte Carlo placebo rule
relations:
  - predicate: derived_from
    target: ../dataset/placebo_event_study_samples.md
    basis: inferred
    qualifiers: simulation benchmark against real placebo sample design
  - predicate: used_by
    target: ../result/montecarlo_results.md
    basis: inferred
---

# Monte Carlo placebo panels

## Construction

Two generators:

1. `lib/create/montecarlo.do` - standalone simulator (10,000 CEO changes, hazard rates per the commented contract), writing `temp/placebo_montecarlo.dta` with fields `frame_id_numeric`, `year`, `TFP`, `ceo_skill`, et al. per the code comments.


2. Paper-specific `papers/econometrics/src/montecarlo/`, scenario `.do` files exercised through the econometrics Makefile, producing Monte Carlo placebo event-study datasets under `papers/econometrics/data/` (e.g. placebo_full sample variants).



## Role

These simulated panels let the paper check whether the placebo matching design recovers zero average effect under the null, benchmarking estimator behavior against simulated data`.

The root Makefile treats the Monte Carlo outputs as PRECIOUS file targets, wiring them into the econometrics estimation chain per [makefile_econometrics](../references/makefile_econometrics.md).



[^mc_code]: Monte Carlo generator code - see [montecarlo.do](../references/code/montecarlo_do.md)
[^make_eco]: Econometrics Makefile - see [makefile_econometrics](../references/makefile_econometrics.md)