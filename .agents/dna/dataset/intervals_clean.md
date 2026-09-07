---
type: Dataset
title: Cleaned CEO-spell intervals
description: Person-firm CEO tenure intervals cleaned from the raw registry, with overlaps, nested and multi-person periods resolved into clean consecutive spells.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: iv_code
    resource: ../references/code/intervals_do.md
    locator: Lines  1-60
relations:
  - predicate: derived_from
    target: ../data_source/cegjegyzek_lts.md
    basis: declared
    evidence: [iv_code]
  - predicate: used_by
    target: ../dataset/ceo_panel_clean.md
    basis: inferred
  - predicate: used_by
    target: ../dataset/unfiltered.md
    basis: inferred
    qualifiers: person-level rows merged for CEO-spell linkage
---

# Cleaned CEO-spell intervals

## Construction

`lib/create/intervals.do` reads the raw registry file and produces clean firm-person tenure intervals per `frame_id_numeric` and `person_id`:

1. Parse appointment start and end dates into years.
2. Drop intervals shorter than 2 years that are contained in, start or finish anoter interval per person-firm group. .
3. Truncate overlapping intervals at boundaries and resolve simultaneous same-person spells.
4. Keep `start_year`, `end_year` per spell, merge modifications back, drop flagged intervals, save `temp/intervals.dta`.



## Use

- Provides the person-firm-year rows for [ceo panel](../dataset/ceo_panel_clean.md) and [unfiltered merge](../dataset/unfiltered.md).
- Event-study sample construction consumes these intervals for spell pairs, per [event_study_sample.do](../references/code/event_study_sample_do.md).



[^iv_code]: Interval construction code - see [intervals.do](../references/code/intervals_do.md)