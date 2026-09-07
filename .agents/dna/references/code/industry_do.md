---
type: Reference
title: Industry classification code
description: Evidence excerpt from lib/util/industry.do, TEAOR08 to sector mapping.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Industry classification code

## Source

- Path: `lib/util/industry.do`
- SHA-256: `46d37d9b2d7f90b46cfb4512df0d2d46ac6ace2583e0c2df2a01503254f754d5`
- Inspected: exact source slices below

## Excerpts

### Lines 3-10
```text
replace sector = 1 if teaor08_1d == "A" // Agriculture, forestry and fishing
replace sector = 2 if teaor08_1d == "B" // Mining and quarrying
replace sector = 3 if teaor08_1d == "C" // Manufacturing
replace sector = 4 if inlist(teaor08_1d, "G", "H") // Wholesale and retail trade; repair of motor vehicles and motorcycles
replace sector = 5 if inlist(teaor08_1d, "J", "M") // Information and communication; Professional, scientific and technical activities
replace sector = 9 if teaor08_1d == "K" // Finance
replace sector = 6 if teaor08_1d == "F" // Construction
replace sector = 7 if missing(sector) // Nontradable services
```

### Lines 12-17
```text
tempvar constant_sector
foreach X in sector teaor08_2d {
    egen `constant_sector' = mode(`X'), by(frame_id_numeric) maxmode
    replace `X' = `constant_sector'
    drop `constant_sector'
}
```

### Lines 19-20
```text
label define sector 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Wholesale, Retail, Transportation" 5 "Telecom and Business Services" 6 "Construction" 7 "Nontradable services" 9 "Finance, Insurance and Real Estate"
label values sector sector
```

## Notes

- Sector 9 (Finance) is excluded later in filter.do.
- Missing one-digit codes are assigned to sector 7 (Nontradable services).
- Both `sector` and the 2-digit `teaor08_2d` are imputed by firm-mode.
