---
type: Claim
title: Founder-managed firms have lower measured manager skill
description: Extract analysis of manager skill by founder status and firm size; consistent with Bloom and Van Reenen autonomy differences.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: ext_code
    resource: ../references/code/extract_do.md
    locator: Lines  4-35
relations:
  - predicate: supported_by
    target: ../result/manager_skill_distributions.md
    basis: declared
    evidence: [ext_code]
---

# Founder-managed firms have lower measured manager skill

## Claim

In the 2015 cross-section, founder/owner-managed firms show lower normalized manager skill on average, with the gap varying by firm size.

## Evidence

Extract do normalizes manager_skill to component mean (shrink 0.25), scales by chi, then summarizes by founder status and sales-size bins. Exact distribution numbers not in the excerpt slices; claim rests on the code pathway.

## Relates

Ties to the appendix claim that family-controlled firms have less managerial autonomy, per the Bloom and Van Reenen replication.

[^ext_code]: [Extract code](../references/code/extract_do.md).
