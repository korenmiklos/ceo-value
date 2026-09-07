---type: Dataset
title: Cleaned CEO panel (firm-year CEO facts)
status: draft
description: "Firm-year CEO aggregation from the registry: counts, founder and expat flags, CEO gender composition."
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: cp_code
    resource: ../references/code/ceo_panel_do.md
    locator: Lines   1-40
relations:
  - predicate: derived_from
    target: ../data_source/cegjegyzek_lts.md
    basis: declared
    evidence: [cp_code]
  - predicate: used_by
    target: ../dataset/unfiltered.md
    basis: inferred
---

# Cleaned CEO panel

## Construction

`lib/create/ceo_panel.do` builds firm-year CEO facts from the registry person-firm intervals:

- one row per firm-year spanning the cleaned [intervals](../dataset/intervals_clean.md).
- `n_ceo` counts the number of CEOs in the firm-year.
- `has_founder` flags any CEO who is an owner-foundermanager category.
- `has_expat_ceo` flags any CEO with foreign-nationality signal in `manager_category` or person attributes.
- `n_ceo_male` counts male CEOs, used in gender-composition variants.





## Use

Merged into the [unfiltered panel](../dataset/unfiltered.md) so firm-year rows carry CEO countsand flags before sample filters.





[^cp_code]: CEO panel construction code - see [ceo_panel.do](../references/code/ceo_panel_do.md)