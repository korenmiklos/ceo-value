---
type: Reference
title: Bloom autonomy analysis code
description: Evidence excerpts from lib/estimate/bloom_autonomy_analysis.do, appendix autonomy analysis.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Bloom autonomy analysis code

## Source

- Path: `lib/estimate/bloom_autonomy_analysis.do`
- SHA-256: `87a7dcfd15e41c39369c42e086e73fbb1958c1614aa6b38d698d7d8585ed4035`
- Inspected: exact source slices below

## Excerpts

### Lines 1-14
```text
*! version 1.0.0 2025-08-29
*! Analyze managerial autonomy in Bloom et al. (2012) data
* =============================================================================
* Purpose: Test whether family-controlled firms have less managerial autonomy
* Data source: Bloom, Sadun & Van Reenen (2012) QJE replication data
* =============================================================================

clear all

* =============================================================================
* Load and prepare data
* =============================================================================
use "input/bloom-et-al-2012/replication.dta", clear

```

### Lines 18-34
```text
* Generate log investment autonomy (exclude zeros)
generate lnI = ln(central5)
label variable lnI "Log investment autonomy"

* Create dummy variables for full autonomy (score = 5)
generate byte hiring = central4 == 5
generate byte marketing = central6 == 5
generate byte product = central7 == 5

label variable hiring "Full hiring autonomy"
label variable marketing "Full sales/marketing autonomy"
label variable product "Full product intro autonomy"

* Count observations
count
count if !missing(central5)
count if !missing(lnI)
```

### Lines 52-79
```text
tabulate central4
tabulate central6
tabulate central7

tabulate cty public, row
tabulate family public

* Cross-tabs for dummy variables
tabulate family hiring if !public, row
tabulate family marketing if !public, row
tabulate family product if !public, row

* =============================================================================
* Define regression options
* =============================================================================
local baseline_fe "absorb(cty)"
local preferred_fe "absorb(cty sic2)"
local robust_fe "absorb(cty sic2 analyst)"
local cluster "cluster(id)"

* =============================================================================
* Main regressions - Loop through autonomy dimensions
* =============================================================================

* Define outcomes and labels
local outcomes "central5 hiring marketing product"
local central5_label "Investment Autonomy (dollar value)"
local hiring_label "Hiring Autonomy (dummy)"
```

## Notes

- Data file `input/bloom-et-al-2012/replication.dta` is NOT present in the current `input/` listing  the rule `table/tableA0.tex` in papers/application/Makefile references it, but the input is missing in this checkout (blocked target`.
- The script's regression details beyond line 80 were not fully excerpted; athe full file was inspected for inventory.
