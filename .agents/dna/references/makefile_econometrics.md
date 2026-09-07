---
type: Reference
title: Econometrics paper Makefile
description: Evidence from papers/econometrics/Makefile, the methods paper pipeline.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Econometrics paper Makefile

## Source

- Path: `papers/econometrics/Makefile`
- SHA-256: `27e54baa55e1c3d9f01285a2aaa1c08a001c788e22c643e3b84e2ecb8d538ec4`
- Inspected: exact source slices below

## Excerpts

### Lines 2-20
```text
STATA := stata-mp

SCENARIOS = baseline persistent excessvariance excessvariance_corr all trend longpanel
OUTCOMES :=  lnR lnL lnK ROA lnRL
SAMPLES := full one2one twos fnd2non non2non gender nogender gap nogap
FIXED_EFFECTS := lnR ROA lnRL
VARIATIONS := full size1 size2 size3 size4 pre2000 post2000
DATALIB := ../../temp/analysis-sample.dta ../../temp/manager_value.dta
CODELIB := ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do

all: $(foreach sample,$(SAMPLES), figure/outcomes_$(sample).pdf) \
	table/r2s_full.tex\
	table/firm-descriptives.tex \
	table/firm-year-descriptives.tex \
	table/switch-descriptives.tex \
	table/industry-descriptives.tex \
	table/atets.tex \
	$(foreach variation,$(VARIATIONS),table/$(variation)_debiased_r2s.tex) \
	figure/ceo-spell-distributions.pdf \
```

### Lines 44-66
```text

data/full_full_ROA-lnR.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" full full ROA no lnR excessvariance

data/full_full_lnK-ROA.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" full full lnK no ROA excessvariance

data/full_full_lnL-lnRL.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" full full lnL no lnRL excessvariance

define atets_RULE
data/atet_$(1)_$(2)_$(3)-$(3).csv: $$(CODELIB) $$(DATALIB) data/$(1)_placebo_$(2).dta
	mkdir -p data
	$$(STATA) -b do ../../lib/estimate/event_study_atet.do $(1) $(2) $(3) no $(3) excessvariance
endef
$(foreach variation,$(VARIATIONS),$(foreach sample,$(SAMPLES),$(foreach outcome,$(OUTCOMES),$(eval $(call atets_RULE,$(variation),$(sample),$(outcome))))))

#################################################################################
####### Monte Carlo :Generate event study data for monte carlo scenarios ########
#################################################################################
```

### Lines 79-89
```text
$(foreach scenario,$(MC_SCENARIOS),$(eval $(call GEN_MC,$(scenario))))

data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
	$(STATA) -b do src/montecarlo/run.do $*

#################################################################################
############################ EXHIBTIS ###########################################
#################################################################################
figure/outcomes_%.pdf: src/exhibit/outcomes.do \
	$(CODELIB) \
	$(foreach outcome, $(OUTCOMES), data/%_$(outcome)-$(outcome).csv)
```

### Lines 100-130
```text
	$(STATA) -b do $<

table/r2s_full.tex: src/exhibit/application_r2s.do $(CODELIB) \
		data/atet_full_full_lnR-lnR.csv \
		data/atet_full_full_lnRL-lnRL.csv \
		data/atet_full_full_ROA-ROA.csv \
		data/atet_full_full_lnL-lnL.csv \
		data/atet_full_full_lnK-lnK.csv
	mkdir -p table
	$(STATA) -b do $< full

define debiased_rule
table/$(1)_debiased_r2s.tex: src/exhibit/debiased_r2s.do $$(CODELIB) \
	$$(foreach sample, $$(SAMPLES),$$(foreach outcome, $$(OUTCOMES), data/atet_$(1)_$$(sample)_$$(outcome)-$$(outcome).csv))
	mkdir -p table
	$$(STATA) -b do $$< $(1)
endef
$(foreach variation, $(VARIATIONS), $(eval $(call debiased_rule,$(variation))))


table/atets.tex: src/exhibit/atets.do $(CODELIB)
	mkdir -p table
	$(STATA) -b do src/exhibit/atets.do

figure/figuremc.pdf: src/figuremc.do  \
	src/exhibit/event_study2.do \
	src/exhibit/event_study3.do \
	mkdir -p figure
	$(STATA) -b do src/figuremc.do

table/%.tex: src/exhibit/%.do $(DATALIB) $(CODELIB)
```

## Notes

- `data/{variation}_placebo_{sample}.dta` is copied from `../../temp/{variation}_placebo_{sample}.dta`; those temp variation files are absent in the current checkout, but the copied outputs `data/atet_full_full_lnR-lnR.csv` etc. EXIST  the pipeline was run when variation temp files existed, which is notverifiable in the current tree.
- Monte Carlo placebo files (baseline, persistent, excessvariance, longpanel, all, unbalanced)are produced by `src/montecarlo/run.do` from scenario `.do` files and exist in `papers/econometrics/data/`.
