---
type: Sample
title: Extract samples
description: "Confidential output extracts for external analysis: 2022 manager values, 2015 transition managers, connected managers with CEO age, and revenue weights."
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: ext_code
    resource: ../references/code/extract_do.md
    locator: Lines  148-185
relations:
  - predicate: selected_from
    target: ../dataset/manager_value.md
    basis: declared
    evidence: [ext_code]
  - predicate: selected_from
    target: ../dataset/surplus.md
    basis: declared
    evidence: [ext_code]
  - predicate: used_by
    target: ../result/extraction_outputs.md
    basis: declared
---

# Extract samples

## Definition

Sub-samples written to output/extract for external analysis by [extract.do](../references/code/extract_do.md):

- Extract 1: manager values in 2015 normalized by component mean, restricted to one-CEO firms.
- Extract 2: 2015-starter managers and previous CEOs from surplus data, one manager before and after 2015.
- Extract 3: connected managers with entry year, age, gender normalized from surplus manager skill.
- Extract 4: revenue-function weights for split CEOs.

## Notes

Extracts 1 and 3 consume temp/surplus.dta whose producer script is missing, flagged as a gap.

[^ext_code]: [Confidential extract code](../references/code/extract_do.md).
