---
type: Result
title: Manager skill distribution statistics
status: draft
description: Descriptive statistics of manager skill estimates, including the distribution by founder status and firm size from the extract analysis.
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: ext_code
    resource: ../references/code/extract_do.md
    locator: Lines  4-35
  - id: mv_code
    resource: ../references/code/manager_value_do.md
    locator: Lines  1-16
relations:
  - predicate: uses_sample
    target: ../sample/extract_samples.md
    basis: declared
    evidence: [ext_code]
---

# Manager skill distributions

## Content

Distributional results from the extract analysis: manager skill normalized to component mean (empirical-Bayes shrink factor 0.25), scaled by chi, and reported conditional on founder status and firm size (sales bins). The results describe how manager-skill estimates vary with firm characteristics.

## Notes

Relevant to the paper's narrative that family/founder-managed firms have lower measured manager skill, consistent with the Bloom and Van Reenen autonomy appendix.

[^ext_code]: [Extract code](../references/code/extract_do.md).
[^mv_code]: [Manager value code](../references/code/manager_value_do.md).