---
type: Dataset
title: Unfiltered firm-year panel with derived variables
description: Pre-filter merge of balance sheet, CEO panel and intervals plus derived log and ratio variables, before sample exclusions.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: un_code
    resource: ../references/code/unfiltered_do.md
    locator: Lines  1-45
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Lines  1-29
  - id: logs
    resource: ../references/logs.md
    locator: unfiltered cohort construction observed in logs
relations:
  - predicate: derived_from
    target: ../dataset/balance_clean.md
    basis: declared
    evidence: [un_code]
  - predicate: derived_from
    target: ../dataset/ceo_panel_clean.md
    basis: declared
    evidence: [un_code]
  - predicate: derived_from
    target: ../dataset/intervals_clean.md
    basis: declared
    evidence: [un_code]
  - predicate: used_by
    target: ../dataset/analysis_sample.md
    basis: declared
---

# Unfiltered firm-year panel

## Construction

`lib/create/unfiltered.do` merges the cleaned balance sheet 1:1 with the CEO panel, then attaches person-firm-year CEO spell rows from the intervals, and writes `temp/unfiltered.dta`. [variables.do](../references/code/variables_do.md) then constructs derived logs, ratios, ROA,, EBITDA_share, intangible_share, has_intangible, max_employment, noted in [variable docs](../variable/sales.md).

Even "unfiltered", the data exclude no-CEO firm-year rows and keep only matched firm-year observations, per the merge step. No sample size recorded for this stage in the logs we read.





## Notes

- The econometrics paper's analysis sample derives from this file via [filter.do](../references/code/filter_do.md).
- README-era counts (8.87M firm-years, 891.6k firms) describe an older sample definition and disagree with the current paper counts.

.



[^un_code]: Unfiltered merge code - see [unfiltered.do](../references/code/unfiltered_do.md)
[^var_code]: Variable construction code - see [variables.do](../references/code/variables_do.md)
[^logs]: Stata execution logs - see [logs](../references/logs.md)
