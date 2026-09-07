---
type: Reference
title: Edgelist construction code
description: Evidence excerpt from lib/create/edgelist.do, firm-manager edgelist extraction.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Edgelist construction code

## Source

- Path: `lib/create/edgelist.do`
- SHA-256: `13e67c64e78d94976b37ac3637ffac576b49776419ba20986862e88f98d7d2de`
- Inspected: exact source slices below

## Excerpts

### Lines 1-16
```text
* get the set of firms in the analysis sample
use "temp/full-analysis-sample.dta", clear
keep frame_id_numeric
duplicates drop
tempfile firms
save "`firms'", replace

* person_id lives in intervals.dta, not in the firm-year panel
use "temp/intervals.dta", clear
keep frame_id_numeric person_id
duplicates drop

* restrict to firms in the analysis sample
merge m:1 frame_id_numeric using "`firms'", keep(match) nogen

export delimited using "temp/edgelist.csv", replace
```

## Notes

- Reads `temp/full-analysis-sample.dta` (variation-named); the observed `edgelist.log` run predates this text and used `temp/analysis-sample.dta` (old naming); see the log reference.
- The observed run matched 1,058,307 firm-person pairs (edgelist.log`.
