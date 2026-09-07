---
type: Reference
title: Main Makefile
description: Evidence from the root Makefile defining the active pipeline targets.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Main Makefile

## Source

- Path: `Makefile`
- SHA-256: `7801bc14042fa12111812ea4e86fd14bc44ac36f934b973be885d19dfeabb5aa`
- Inspected: exact source slices below

## Excerpts

### Lines 1-17
```text
# =============================================================================
# CEO Value Research Project Makefile
# Implements novel placebo-controlled event study design
# =============================================================================

# Tool definitions
STATA := stata-mp -b do
JULIA := julia --project=.
LATEX := pdflatex
PANDOC := pandoc
UTILS := $(wildcard lib/util/*.do)

ANALYSIS_VARIATIONS := full size1 size2 size3 size4 pre2000 post2000
SAMPLES := full one2one twos fnd2non non2non gender nogender gap nogap
OUTCOMES := lnK lnWL lnM has_intangible

# Commit hashes for reproducible file extraction
```

### Lines 38-77
```text
.PHONY: data

# Data wrangling pipeline
data: temp/manager_value.dta \
	$(foreach sample, $(SAMPLES),$(foreach variation, $(ANALYSIS_VARIATIONS), temp/$(variation)_placebo_$(sample).dta))

install: install.log

# =============================================================================
# Data wrangling
# =============================================================================

# Process raw balance sheet data
temp/balance.dta: lib/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

# Create manager facts lookup tables
temp/manager-firm-facts.dta temp/manager-facts.dta: lib/create/manager-facts.do input/manager-db-ceo-panel/ceo-panel.dta
	$(STATA) $<

# Process CEO panel data
temp/ceo-panel.dta: lib/create/ceo-panel.do input/manager-db-ceo-panel/ceo-panel.dta temp/intervals.dta temp/manager-firm-facts.dta temp/manager-facts.dta lib/util/potholes.do
	$(STATA) $<

# Create analysis sample
temp/%-analysis-sample.dta: lib/create/analysis-sample.do temp/unfiltered.dta lib/util/filter.do
	$(STATA) $< $*

# Generate placebo CEO transitions
define GEN_PLACEBO
temp/$(1)_placebo_$(2).dta: lib/create/event_study_sample.do temp/$(1)-analysis-sample.dta temp/manager_value.dta
	$$(STATA) $$< $(1) $(2)
endef
$(foreach variation, $(ANALYSIS_VARIATIONS), $(foreach sample, $(SAMPLES), $(eval $(call GEN_PLACEBO,$(variation),$(sample)))))

# Extract firm-manager edgelist
temp/edgelist.csv: lib/create/edgelist.do temp/full-analysis-sample.dta
	$(STATA) $<

# Find largest connected component of managers
```

### Lines 85-93
```text
# Create unfiltered dataset for table creation
temp/unfiltered.dta: lib/create/unfiltered.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
	$(STATA) $<

# Create cleaned CEO tenure intervals
temp/intervals.dta: lib/create/intervals.do input/manager-db-ceo-panel/ceo-panel.dta lib/util/potholes.do
	$(STATA) $<

# =============================================================================
```

## Notes

- The root Makefile's `data` target expects variation-named outputs (`temp/{variation}_placebo_{sample}.dta` and `temp/{variation}-analysis-sample.dta`) that DO NOT exist in the current `temp/` listing; only the older names (`temp/analysis-sample.dta`, `temp/placebo_full.dta`, etc. exist. The pipeline described here has not been re-run in this checkout.
- `make all` is referenced in README/CLAUDE.md but NOT defined in this Makefile (no such target; the Makefile supports `data`, `install`, and file-specific targets`  `make all` would fail. A coverage note.
- The Makefile has no rules for `lib/estimate/surplus.do`, `lib/estimate/anova.do`, or `lib/estimate/revenue_function.do`  those targets exist only in the paper Makefiles.
