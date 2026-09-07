---
type: Build record
title: Build record, 2026-09-07
description: Inputs observed, scripts traced, artifacts inventoried, and gaps recorded for this replication-wiki build.
status: draft
build_id: 2026-09-07
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Build record, 2026-09-07

## Checkout state

- Repo root: /Users/koren/Tresorit/Mac/projects/ceo-value
- Build id: 2026-09-07
- Active paper: papers/econometrics/paper_july2026.tex (June 2026)
- Application-era paper: papers/application/paper.tex

## Raw inputs observed

- input/merleg-LTS-2023/balance/balance_sheet_80_22.dta (consumed by pipeline)
- input/merleg-LTS-2023/machine/balance_sheet_80_22_machine.dta (not consumed by traced scripts)
- input/merleg-LTS-2023/address/{hq,site,branch}_panel_80_22.dta (not consumed)
- input/manager-db-ceo-panel/ceo-panel.dta (consumed)
- input/manager-db-ceo-panel/{ceo-spell-intervals,ceo-spell-panel,manager-id,manager-panel}.dta (not consumed by traced scripts)
- input/manager-db-ceo-panel/rovat_13_histograms/ (validation artifacts)
- input/bloom-et-al-2012/replication.dta ABSENT (blocked appendix target)

## Pipeline traces

- balance.do -> temp/balance.dta
- intervals.do -> temp/intervals.dta
- manager-facts.do -> temp/manager-facts.dta, temp/manager-firm-facts.dta
- ceo_panel.do -> CEO panel facts
- unfiltered.do -> temp/unfiltered.dta
- variables.do -> derived logs/ratios/ROA
- filter.do + analysis-sample.do -> analysis sample (observed deletions 525,629; 1,187; 515,834; 102,785; 1,507,538)
- edgelist.do -> temp/edgelist.csv (1,058,307 pairs matched in log)
- connected_component.jl -> large_component_managers.csv (min size 30)
- leverage.jl -> edgelist_leverage.csv
- manager_value.do -> temp/manager_value.dta, temp/manager_value_spell.dta
- event_study_sample.do -> placebo event-study samples
- event_study.do -> setup_event_study.do -> xt2var.do estimator chain
- revenue_function.do -> temp/revenue_models.ster
- montecarlo.do + papers/econometrics/src/montecarlo -> Monte Carlo placebo panels

## Artifacts observed

- temp/analysis-sample.dta, temp/placebo_full.dta, placebo_fnd2non.dta, placebo_full.dta (old naming)
- temp/surplus.dta (97.5MB; producer surplus.do missing)
- papers/application/table/table2.tex, tableA3.tex, tableA4.tex, tableA1.tex
- papers/econometrics/table/r2s_full.tex
- papers/econometrics/data/*.csv (407 CSVs, 355 ATET)

## Gaps

- lib/estimate/surplus.do MISSING
- lib/estimate/anova.do MISSING
- input/bloom-et-al-2012/replication.dta MISSING
- temp variation-named files absent (root Makefile expects them)
- tableA4 producer script not found
- ceo_age_sq, ceo_tenure_sq not constructed in traced variables.do
- root Makefile `all` target undefined
- code/ path in README/CLAUDE stale (lib/ is current)
*/