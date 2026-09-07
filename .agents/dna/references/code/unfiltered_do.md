---
type: Reference
title: Unfiltered merge code
description: Evidence excerpt from lib/create/unfiltered.do, merging balance sheet and CEO panels with classifications.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Unfiltered merge code

## Source

- Path: `lib/create/unfiltered.do`
- SHA-256: `57775f1f0520f837462fef9dcd809c79cff9d9607da239e3ff2a80437d357f4f`
- Inspected: exact source slices below

## Excerpts

### Lines 9-23
```text
use "temp/balance.dta", clear
* create investment here while it is a firm-year panel
xtset frame_id_numeric year

merge 1:1 frame_id_numeric year using "temp/ceo-panel.dta", keep(match) nogen

* Apply industry classification
do "lib/util/industry.do"
do "lib/util/variables.do"

* even in unfiltered data, firms that never report a CEO are dropped
drop if max_ceo_spell == 0

* Save unfiltered dataset
save "temp/unfiltered.dta", replace
```

## Notes

- 1:1 merge on firm-year keeps only matched observations (balance sheet  CEO panel}.
- Firms that never report a CEO are excluded even before sample filters (line 20}.
