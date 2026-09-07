---
type: Reference
title: Network sample helper code
description: Evidence excerpt from lib/create/network-sample.do, connected component flags.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Network sample helper code

## Source

- Path: `lib/create/network-sample.do`
- SHA-256: `a7424b7e63d8d35f83ebd6e89fbdfdccef44dec441ce05160e36bf8c2526da13`
- Inspected: exact source slices below

## Excerpts

### Lines 1-19
```text
* Import the large connected component managers with component IDs
preserve
import delimited "temp/large_component_managers.csv", clear
tempfile managers_in_large_components
save `managers_in_large_components'
restore

* Merge component IDs
merge m:1 person_id using `managers_in_large_components'
replace component_id = 0 if _merge == 1
replace component_size = 0 if _merge == 1

* define network sample so that we can reuse it in all tables and regressions
generate byte giant_component = (component_id == 1)
generate byte connected_components = (component_size >= 30)

drop _merge

* Display component distribution
```

## Notes

- `connected_components` flags managers in components with at least 30 members; `giant_component` flags the largest component (component_id == 1}.
- Managers outside listed components get component_id/component_size = 0.
