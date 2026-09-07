---
type: Data source
title: Cégjegyzék LTS - Hungarian Firm Registry / CEO Panel Data
description: Proprietary administrative Hungarian firm registry data covering registration, ownership and executive appointments, distributed by HUN-REN KRTK, originally published by Opten Zrt.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: readme
    resource: ../references/readme.md
    locator: Line  1016 (sample counts from the 2026 econometrics paper)
  - id: paper_app
    resource: ../references/paper_application.md
    locator: Lines  1-30 (firm registry description in Data Construction section, excerpt only lines 232-267 in the working session)

    resource: ../build/2026-09-07/record.md
    locator: Input inventory (observed files, see record.md)
relations: []
---

# Cégjegyzék LTS - Hungarian Firm Registry / CEO Panel Data

## Origin and access

The Cégjegyzék LTS dataset includes information on firm registration, ownership structure,and executive appointments. It is distributed by HUN-REN KRTK, originally published by Opten Zrt.; proprietary, not shareable.



Raw registry files present under `input/manager-db-ceo-panel/`:

- `ceo-panel.dta` - manager-firm-year registry records, consumed by the pipeline.
- `ceo-spell-intervals.dta`, `ceo-spell-panel.dta`, `manager-id.dta`, `manager-panel.dta` - additional derived registry files, not consumed by traced scripts in this checkout.
- `rovat_13_histograms/` - histogram PNGs and CSV sanity tables, validation artifacts.



## Contents

CEO characteristics include gender, birth year, manager category, ownership status. The application paper describes CEO identification heuristics: explicit "managing director" titles; otherwise all representatives are CEOs if 3 at the firm; continuity-based assignment otherwise; numeric identifiers only from 2013, requiring entity resolution before that.



## Use in pipeline

Consumed by [intervals.do](../dataset/intervals_clean.md), [manager-facts.do](../dataset/manager_facts.md), and for extracts [extract.do](../references/code/extract_do.md). The pipeline person-level identifiers are `person_id`; firm-level `frame_id_numeric`.

Raw-file contents were not read in this build, binary .dta and confidential; content descriptions are declared, not observed.



[^readme]: README data availability statements - see [README](../references/readme.md)
[^paper_app]: Application paper text - see [paper.tex](../references/paper_application.md), lines 232-267 describe registry construction
[^input_listing]: Build record input inventory - see [record](../build/2026-09-07/record.md)
[^extract_code]: Extract construction code - see [extract.do](../references/code/extract_do.md)
