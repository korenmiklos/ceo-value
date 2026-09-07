---
type: Variable
title: CEO spell
description: Numbered tenure interval of a CEO within a firm; zero denotes firm-years with no CEO.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: var_code
    resource: ../references/code/variables_do.md
    locator: Line  33
  - id: fl_code
    resource: ../references/code/filter_do.md
    locator: Lines  21-88
relations:
  - predicate: defined_in
    target: ../dataset/intervals_clean.md
    basis: declared
    evidence: [var_code]
---

# CEO spell

## Definition

`ceo_spell` numbers the consecutive tenure intervals of a CEO at a firm, constructed in [intervals.do](../references/code/intervals_do.md). `ceo_spell = 0` denotes firm-years with no CEO. The event-study analysis requires consecutive spell pairs, dropping single-spell and gapped firms.

## Use

Filtering: [filter.do](../references/code/filter_do.md) drops firm-years with `ceo_spell == 0`. Transition construction identifies a CEO change when the spell index increments.

[^var_code]: [Derived variable construction code](../references/code/variables_do.md).