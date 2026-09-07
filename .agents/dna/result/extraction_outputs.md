---
type: Result
title: Confidential data extracts
description: output/extract/ artifacts for external analysis:2022 manager values (value_bins.csv,, manager_changes_2015.dta,, connected_managers.dta).
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: extract_code
    resource: ../references/code/extract_do.md
    locator: Lines  4-158
  - id: readme
    resource: ../references/readme.md
    locator: Lines  148-185 (extract descriptions)
relations:
  - predicate: uses_sample
    target: ../sample/extract_samples.md
    basis: declared
    evidence: [extract_code]
    role: sample
  - predicate: uses_variable
    target: ../variable/manager_skill.md
    basis: inferred
    evidence: [extract_code]
    role: outcome
---

# Confidential data extracts

## Contents (declared

1. **2022 manager values** - `output/extract/value_bins.csv`: firm FE and manager skill for firms/components, 2015, collapsed by size x founder bins; EBITDA-based manager value.[^readme][^extract_code]
2. **2015 manager changes** - `output/extract/manager_changes_2015.dta`: firms with CEO transitions in 2015 (single-manager before/after, excluding transition years 2014-2015), surplus changes (`surplus_change = (TFP_after - TFP_before)/chi`.,[^extract_code]
3. **Connected component managers** - `output/extract/connected_managers.dta`: person-level `manager_skill, entry_year, birth_year, hungarian_name, male` for connected-component managers with skill.[^extract_code]

## Observed artifacts

- `output/extract/manager_changes_2015.dta` existsin output listing; `value_bins.csv` and `connected_managers.dta` were not re-verified in the truncated listing (output listing showed `output/extract/manager_changes_2015.dta`; files may exist unscanned. Coverage note.

## Gaps

- Extracts 1 and 3 consume `temp/surplus.dta`, whose producer script is missing (see [surplus dataset](../dataset/surplus.md)); their reproducibility is blocked in the current checkout.- Extract 2 converts `sales` to million HUF (divides by 1e3recordedas sales/1e3 in code - declared, not unit-verified.



[^extract_code]: [Confidential extract code](../references/code/extract_do.md)
[^readme]: [README](../references/readme.md)
