---
type: Reference
title: Pothole filling code
description: Evidence excerpt from lib/util/potholes.do, filling 1-2 year gaps in CEO spells.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Pothole filling code

## Source

- Path: `lib/util/potholes.do`
- SHA-256: `6a4bfc950174741c18eab92287d060ee8e57e104dee83514997c0bcc89c5815a`
- Inspected: exact source slices below

## Excerpts

### Lines 17-30
```text
egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

* we are glossing over potholes of 1 or 2 years
bysort fp (year): generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
* number of clones to create of CEO
generate clones = 1
forvalues t = 1/2 {
    replace clones = `t' + 1 if gap == `t'
}
expand clones
bysort fp year: replace year = year - _n + 1

```

### Lines 33-37
```text
* test whether potholes have been filled
bysort frame_id_numeric person_id (year): generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
tabulate gap, missing
assert gap == 0 | gap > 2
```

### Lines 40-50
```text
* =============================================================================
* SPELL COMPUTATION
* =============================================================================
egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

generate byte entering_ceo = missing(L.year)

* the same person may have multiple spells at the firm
bysort frame_id_numeric person_id (year): generate spell = sum(entering_ceo)
egen start_year = min(year), by(frame_id_numeric person_id spell)
```

## Notes

- Called from `lib/create/intervals.do`; requires `frame_id_numeric`, `person_id`, `year` in memory.
- Glosses over gaps of 1 or 2 years within a firm-person series by interpolated rows; the assertion `gap == 0 | gap > 2` verifies post-fill spacing.
