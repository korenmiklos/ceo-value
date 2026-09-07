---
type: Sample
title: Bloom and Van Reenen autonomy sample
status: draft
description: Cross-country management survey observations for the appendix autonomy analysis; blocked because the replication input is absent.
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: bloom_code
    resource: ../references/code/bloom_autonomy_do.md
    locator: Lines  1-14
  - id: make_app
    resource: ../references/makefile_application.md
    locator: Line  157
relations:
  - predicate: selected_from
    target: ../data_source/bloom_et_al_2012.md
    basis: declared
    evidence: [bloom_code]
    qualifiers: input file input/bloom-et-al-2012/replication.dta absent in checkout
---

# Bloom and Van Reenen autonomy sample

## Definition

Survey observations on plant-manager autonomy (central4-central7 hiring, investment, sales, product autonomy) plus public, family, country, industry, firm id controls. Used to test whether family-controlled firms show less managerial autonomy, appendix table A0.

## Status

Blocked in this checkout: input/bloom-et-al-2012/replication.dta is absent, so the make target cannot run.

[^bloom_code]: [Bloom autonomy analysis code](../references/code/bloom_autonomy_do.md).