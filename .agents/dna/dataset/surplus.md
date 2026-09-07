---
type: Dataset
title: Surplus shares artifact
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
description: "temp/surplus.dta, artifact with estimated surplus shares and manager-related fields; producer script missing from the checkout, so generation steps are untraceable."
sources:
  - id: make_app
    resource: ../references/makefile_application.md
    locator: Lines  93-95
  - id: make_eco
    resource: ../references/makefile_econometrics.md
    locator: Lines  64-65 and  148-149
  - id: file_list
    resource: ../build/2026-09-07/record.md
    locator: Input inventory (observed temp files)
relations: []
---

# Surplus shares artifact

## Status

`temp/surplus.dta` exists in the current checkout as a large artifact,listed in the observed temp inventory per the [build record](../build/2026-09-07/record.md). Its producer script `lib/estimate/surplus.do` is MISSING from the checkout, so this build cannot trace its generation; flagged as a gap.




- The econometrics Makefile references surplus files at lines 64-65 and 148-149, per [makefile_econometrics](../references/makefile_econometrics.md).



- Extract jobs 1 andand  3 consume `temp/surplus.dta` per [extract.do](../references/code/extract_do.md), writing outputs under `output/extract/`.



## Fields attested by extractor

[extract.do](../references/code/extract_do.md), lines   64-101, uses `temp/surplus.dta` and collapses by firm-and-period: `TFP` plus `person_id` and `chi` via `firstnm`; `T_spell` counted per transition period, with `year`, `frame_id_numeric`, `ceo_spell` as grouping fields. The file therefore carries these fields per the extractor locator; the producing script `surplus.do` is missing, so native generation steps are untraceable.


[^make_app]: Application Makefile - see [makefile_application](../references/makefile_application.md)
[^make_eco]: Econometrics Makefile - see [makefile_econometrics](../references/makefile_econometrics.md)
[^file_list]: Build record input inventory - see [record](../build/2026-09-07/record.md)
[^extract_code]: Extract construction code - see [extract.do](../references/code/extract_do.md)
