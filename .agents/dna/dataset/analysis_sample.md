---type: Dataset
title: Analysis sample (filtered firm-year panel)
status: draft
description: "Firm-year panel after CEO-spell, governance, age, sector and employment filters, with variation variants full, size1-4 and pre/post-2000."
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: fl_code
    resource: ../references/code/filter_do.md
    locator: Lines   21-88
  - id: as_code
    resource: ../references/code/analysis_sample_do.md
    locator: Lines   1-15
  - id: logs
    resource: ../references/logs.md
    locator: "analysis-sample.log (observed run: deletions 525,629;  1,187;  515,834;  102,785;  1,507,538)"
relations:
  - predicate: selected_from
    target: ../dataset/unfiltered.md
    basis: declared
    evidence: [fl_code, as_code]
  - predicate: depends_on
    target: ../variable/ceo_spell.md
    basis: declared
    evidence: [fl_code]
    qualifiers: drops ceo_spell zero
  - predicate: depends_on
    target: ../variable/max_employment.md
    basis: declared
    evidence: [fl_code]
    qualifiers: drops max_employment under 3
---

# Analysis sample

## Filters

[filter.do](../references/code/filter_do.md) applies, in order:

1. Drop firm-years with no CEO (`ceo_spell` zero).
2. Drop firms ever with more than 2 CEOs in one year (`max_n_ceo` over 2).
3. Drop firms with more than 12 CEO spells (`max_ceo_spell` over 12).
4. Drop firm-age zero (incomplete first year).
5. Drop sector 9 (Finance; mining mentioned in comment but not coded.

6. Drop firms never reaching 3 employment (`max_employment` under 3.
7. Drop missing `lnR`, `ROA`, `lnL`, `lnK`, `lnRL`, `export`.



## Variation variants

`analysis-sample.do` keeps variant rows by argument:

- `full` no extra restriction.
- `size1` .. `size4` employment bins 5, 5-10, 10-25, over 25.
- `pre2000`, `post2000` years to 2000, over 2000.


## Counts

Observed log run (old naming, wrote `temp/analysis-sample.dta`; deletion sequence above. Paper (July 2026 counts 471 thousand firms and 4,363,067 firm-years. README cites different-era counts as of an older pipeline.




[^fl_code]: Filter code - see [filter.do](../references/code/filter_do.md)
[^as_code]: Analysis sample construction - see [analysis_sample.do](../references/code/analysis_sample_do.md)
[^logs]: Stata execution logs - see [logs](../references/logs.md)
