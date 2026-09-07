---
type: Reference
title: Manager facts construction code
description: Evidence excerpt from lib/create/manager-facts.do, manager-level and firm-manager fact tables.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Manager facts construction code

## Source

- Path: `lib/create/manager-facts.do`
- SHA-256: `5f5aad370795945c0594ded8cc9f1f95b09e87493e8081fc900c5c98aa081f3f`
- Inspected: exact source slices below

## Excerpts

### Lines 1-13
```text
use "input/manager-db-ceo-panel/ceo-panel.dta", clear

keep frame_id_numeric person_id male birth_year manager_category owner
generate byte hungarian_name = !missing(male)
duplicates drop 

preserve
    drop male birth_year hungarian_name
    save "temp/manager-firm-facts.dta", replace
restore

collapse (firstnm) male birth_year (max) hungarian_name, by(person_id)
save "temp/manager-facts.dta", replace
```

## Notes

- `hungarian_name` is defined as `!missing(male)`  gender is inferred only from Hungarian names (per variables.do comment: "we only infer gender from Hungarian names".
- Dual outputs: firm-manager facts (`temp/manager-firm-facts.dta`) and manager-level facts (`temp/manager-facts.dta`).
