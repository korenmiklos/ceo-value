---
type: Sample
title: Full analysis sample
description: The unfiltered, full-variant analysis sample used by the main specifications; 471 thousand firms and 4,363,067 firm-years per June 2026 paper.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: fl_code
    resource: ../references/code/filter_do.md
    locator: Lines  21-88
  - id: as_code
    resource: ../references/code/analysis_sample_do.md
    locator: Lines  1-15
  - id: paper_eco
    resource: ../references/paper_econometrics.md
    locator: Line  1016 (counts)
relations:
  - predicate: selected_from
    target: ../dataset/analysis_sample.md
    basis: declared
    evidence: [fl_code, as_code]
---

# Full analysis sample

## Definition

The `full` variant of the analysis sample, i.e. all firm-years passing the [filter.do](../references/code/filter_do.md) eligibility rules without size or period restriction. Contains 471 thousand firms and 4,363,067 firm-years per the June 2026 paper.[^paper_eco] The observed one-arg run also saved `temp/analysis-sample.dta` under the old naming.

## Estimation use

Used by the event-study estimator chain, variance-share decompositions, and the network-restricted revenue-function model baseline.

[^paper_eco]: [Econometrics paper text](../references/paper_econometrics.md) line 1016.
[^fl_code]: [Filter code](../references/code/filter_do.md).
[^as_code]: [Analysis sample code](../references/code/analysis_sample_do.md).