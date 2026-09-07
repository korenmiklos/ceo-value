---
type: Reference
title: Stata execution logs
description: Evidence from root Stata batch logs, documenting observed runs of pipeline scripts.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Stata execution logs

### analysis-sample.log (observed run)

- Path: `analysis-sample.log`
- SHA-256: `b888a2457b3cfc4afe0f4fdf83ca4970757179cf2a66c89651af01816d1cfc43`

```text
. do lib/create/analysis-sample.do 
(0 observations deleted)
(525,629 observations deleted)
(1,187 observations deleted)
(515,834 observations deleted)
(102,785 observations deleted)
(1,507,538 observations deleted)
. save "temp/analysis-sample.dta", replace
```

### event_study_sample.log (observed run)

- Path: `event_study_sample.log`
- SHA-256: `f5f70251a9d3318c3ea9066458a8442afda50951d280610639da24dee0990891`

```text
. do lib/create/event_study_sample.do full 
. use "temp/analysis-sample.dta", clear
```

### edgelist.log (observed run)

- Path: `edgelist.log`
- SHA-256: `f3eecd93f503ef64851736b831066e944418adfc79ff05d7adf22cbbeba5928f`

```text
    Matched                         1,058,307  
. export delimited using "temp/edgelist.csv", replace
file temp/edgelist.csv saved
```

### manager_value.log (observed run)

- Path: `manager_value.log`
- SHA-256: `5bcdabc9b4eabd0886d7bbb43c3b4781fe95f2e9a292a1e50311fb89fd2f0efe`

```text
file temp/manager_value_spell.dta saved
file temp/manager_value.dta saved
end of do-file
```

## Notes

- These logs attest to observed runs of the OLD (pre-variation) flow:`temp/analysis-sample.dta`, `temp/placebo_{sample}.dta`, `temp/edgelist.csv`, `temp/manager_value*.dta`.
- `event_study.log` (root) shows a FAILED run: `do lib/estimate/event_study.do large has_intangible`  `file data/placebo_large.dta not found r(601);`  evidence that the one-arg sample convention was already being migrated at that point.
