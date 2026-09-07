---
type: Reference
title: Analysis sample construction code
description: Evidence excerpt from lib/create/analysis-sample.do, sample variation entry point.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Analysis sample construction code

## Source

- Path: `lib/create/analysis-sample.do`
- SHA-256: `c5c3934444e0317343643989bac7543094ea0d3117084c8ff2be7abd22428395`
- Inspected: exact source slices below

## Excerpts

### Lines 1-15
```text
args sample
confirm existence `sample'

local valid_samples full pre2000 post2000 size1 size2 size3 size4
assert strpos(" `valid_samples' ", " `sample' ") > 0

use "temp/unfiltered.dta", clear

* Note: unfiltered.dta already contains merged balance sheet and CEO data
* with industry classification and variables applied
do "lib/util/filter.do" `sample'

compress

save "temp/`sample'-analysis-sample.dta", replace
```

## Notes

- THIS file saves variation-named outputs (`temp/`sample'-analysis-sample.dta`), e.g. `temp/full-analysis-sample.dta`; the old naming `temp/analysis-sample.dta` appears only in root logs and the application paper Makefile.
