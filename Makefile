# =============================================================================
# CEO Value Research Project Makefile
# Implements novel placebo-controlled event study design
# =============================================================================

# Tool definitions
STATA := stata -b do
JULIA := julia --project=.
LATEX := pdflatex
PANDOC := pandoc
UTILS := $(wildcard lib/util/*.do)

SAMPLES := full fnd2non non2non small large
OUTCOMES := lnK lnWL lnM has_intangible

# Commit hashes for reproducible file extraction
# Update these when you need specific versions of files from other branches
COMMIT_MAIN := HEAD  # Update with specific hash when needed, e.g., abc123f
COMMIT_PLACEBO := placebo  # Update with specific hash when needed
COMMIT_EXPERIMENT := experiment/preferred  # Update with specific hash when needed

# Define costly intermediate files to preserve
PRECIOUS_FILES := temp/balance.dta temp/ceo-panel.dta temp/unfiltered.dta \
                  temp/analysis-sample.dta temp/placebo.dta temp/edgelist.csv \
                  temp/large_component_managers.csv \
                  temp/manager_value.dta temp/revenue_models.ster $(foreach sample,$(SAMPLES),temp/placebo_$(sample).dta)

# Mark these files as PRECIOUS so make won't delete them
.PRECIOUS: $(PRECIOUS_FILES)

# =============================================================================
# Main targets
# =============================================================================

.PHONY: data

# Data wrangling pipeline
data: temp/manager_value.dta

install: install.log

# =============================================================================
# Data wrangling
# =============================================================================

# Process raw balance sheet data
temp/balance.dta: lib/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

# Process CEO panel data
temp/ceo-panel.dta: lib/create/ceo-panel.do input/manager-db-ceo-panel/ceo-panel.dta
	$(STATA) $<

# Create analysis sample
temp/analysis-sample.dta: lib/create/analysis-sample.do temp/unfiltered.dta lib/util/filter.do
	$(STATA) $<

# Generate placebo CEO transitions
temp/placebo_%.dta: lib/create/event_study_sample.do temp/analysis-sample.dta temp/manager_value.dta 
	$(STATA) $< $*

# Extract firm-manager edgelist
temp/edgelist.csv: lib/create/edgelist.do temp/analysis-sample.dta
	$(STATA) $<

# Find largest connected component of managers
temp/large_component_managers.csv: lib/create/connected_component.jl temp/edgelist.csv
	$(JULIA) $<

# Create unfiltered dataset for table creation
temp/unfiltered.dta: lib/create/unfiltered.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
	$(STATA) $<

# Create cleaned CEO tenure intervals
temp/intervals.dta: lib/create/intervals.do input/manager-db-ceo-panel/ceo-panel.dta
	$(STATA) $<

# =============================================================================
# Statistical analysis
# =============================================================================

# Estimate manager fixed effects and variance decomposition components
temp/manager_value.dta: lib/estimate/manager_value.do temp/analysis-sample.dta temp/large_component_managers.csv lib/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<


# Balance estimation (alternative analysis)
balance.log: lib/estimate/balance.do temp/analysis-sample.dta lib/create/network-sample.do
	$(STATA) $<

# Test placebo analysis
output/test/placebo_test.log: lib/test/placebo.do output/test/placebo.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# =============================================================================
# Utilities
# =============================================================================

# Install Stata packages
install.log: lib/util/install.do
	$(STATA) $<
