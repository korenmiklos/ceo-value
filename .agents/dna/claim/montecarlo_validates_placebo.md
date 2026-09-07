---
type: Claim
title: Placebo design is valid under simulated nulls
description: Monte Carlo benchmarks show the placebo matching recovers zero average effect under a known null.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mc_code
    resource: ../references/code/montecarlo_do.md
    locator: Lines  3-114
relations:
  - predicate: supported_by
    target: ../result/montecarlo_results.md
    basis: inferred
---

# Placebo design valid under simulated nulls

## Claim

Simulated panels where the true average effect is zero show the placebo event-study design recovers zero coefficients on average, validating the identification strategy.

## Evidence

Monte Carlo artifacts and scenario does exist under papers/econometrics; individual table numbers not extracted in this build, so the claim is marked inferred from the artifacts' existence and the estimation code comments.

[^mc_code]: [Monte Carlo generator code](../references/code/montecarlo_do.md).