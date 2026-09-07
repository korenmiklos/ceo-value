---
type: Dataset
title: Placebo event-study samples
description: Pseudo-firm transition panels matching treated CEO replacements to placebo non-transition firms on cohort, sector, size and window; used by the econometrics estimators.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: ess_code
    resource: ../references/code/event_study_sample_do.md
    locator: Lines  1-247
  - id: logs
    resource: ../references/logs.md
    locator: event_study_sample.log (observed run do event_study_sample.do full, old one-arg flow
relations:
  - predicate: derived_from
    target: ../dataset/analysis_sample.md
    basis: declared
    evidence: [ess_code]
  - predicate: derived_from
    target: ../dataset/manager_value_spell.md
    basis: declared
    evidence: [ess_code]
  - predicate: used_by
    target: ../result/event_study_figures.md
    basis: inferred
---

# Placebo event-study samples

## Construction

[event_study_sample.do](../references/code/event_study_sample_do.md) builds pseudo-firm transition panels:

1. Firm-level `max_n_ceo` at most 2 and `ceo_spell` within clean spells; non-missing ROA.
2. Collapse to spell level with mean skill, spell length, change year, window end, matching strata; keep consecutive spell pairs, dropping single-spell and gapped firms.

3. Treated side: take all clean transitions meeting the sample variant (`full`, `fnd2non`, `non2non`, `small`, `large`, `one2one`, `twos`, `gap`, `nogap`, `gender`, `nogender`).
4. Control side: sample non-transition firms whose uninterrupted CEO spell window contains the event window, probability proportional to 10 times treated count over control count, seed 1391; placebo change year drawn from treated t0 distribution; weight treated count over control count.
5. `fake_id` unifies treated and placebo pseudo-firms; T1 and T2 define event-time window bounds, per [variable docs](../variable/placebo.md).



## Files

- Current convention: `temp/{variation}_placebo_{sample}.dta` (e.g. `temp/full_placebo_full.dta`), referenced by the root Makefile।
- Older observed artifacts: `temp/placebo_full.dta`, `placebo_fnd2non.dta`, et al., from the one-arg run.
- The application paper copies `../../temp/placebo_%` into `data/` per its Makefile, an older naming.





[^ess_code]: Placebo event study sample construction code - see [event_study_sample.do](../references/code/event_study_sample_do.md)
[^logs]: Stata execution logs - see [logs](../references/logs.md)