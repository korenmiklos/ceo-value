---
type: Reference
title: Data flow documentation
description: Evidence excerpts from doc/data-flow.md, pipeline summary.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Data flow documentation

## Source

- Path: `doc/data-flow.md`
- SHA-256: `7eff2ae6cc9b7284f685b8e8eb75b6fee7e6fade1e00cff62070b2b7fe8b80ed`
- Inspected: exact source slices below

## Excerpts

### Lines 1-3
```text
# CEO Value Research Project - Data Flow Pipeline

## 1. Raw Data Sources
```

### Lines 180-185
```text
    - Compute sampling probability to achieve 10:1 control-to-treated ratio
  - Generate placebo transitions:
    - Loop over cohorts; joinby matching strata to candidate control firms
    - Restrict to controls with windows weakly larger than event window
    - Sample controls with probability proportional to target ratio
    - Assign placebo change year by sampling t0 distribution from treated firms
```

## Notes

- The doc describes the pipeline with one-arg placebo samples (`placebo_{sample}.dta`, full/one2one/twos); the current root Makefile instead uses two-arg variations. The doc predates the variation refactor.
