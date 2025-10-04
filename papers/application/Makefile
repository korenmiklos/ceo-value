# =============================================================================
# CEO Value Research Project Makefile - Application Paper
# Implements novel placebo-controlled event study design
# =============================================================================

# Tool definitions
STATA := stata -b do
JULIA := julia --project=../..
LATEX := pdflatex
PANDOC := pandoc
UTILS := $(wildcard ../../lib/util/*.do)

SAMPLES := full fnd2non non2non post2004
OUTCOMES := TFP lnK lnWL lnM has_intangible

# Commit hashes for reproducible file extraction
# Update these when you need specific versions of files from other branches
COMMIT_MAIN := HEAD  # Update with specific hash when needed, e.g., abc123f
COMMIT_PLACEBO := placebo  # Update with specific hash when needed
COMMIT_EXPERIMENT := experiment/preferred  # Update with specific hash when needed

# Define costly intermediate files to preserve
PRECIOUS_FILES := ../../temp/balance.dta ../../temp/ceo-panel.dta ../../temp/unfiltered.dta \
                  ../../temp/analysis-sample.dta ../../temp/placebo.dta ../../temp/edgelist.csv \
                  ../../temp/large_component_managers.csv ../../temp/surplus.dta \
                  ../../temp/manager_value.dta ../../temp/revenue_models.ster $(foreach sample,$(SAMPLES),../../temp/placebo_$(sample).dta)

# Mark these files as PRECIOUS so make won't delete them
.PRECIOUS: $(PRECIOUS_FILES)

# =============================================================================
# Main targets
# =============================================================================

.PHONY: all install data analysis report event_study

# Complete workflow: data → analysis → report
all: report

# Install dependencies and setup
install: install.log

# Data wrangling pipeline
data: ../../temp/unfiltered.dta ../../temp/analysis-sample.dta ../../temp/placebo.dta ../../temp/large_component_managers.csv

# Statistical analysis pipeline  
analysis: ../../temp/surplus.dta ../../temp/manager_value.dta ../../temp/event_study_panel_a.dta ../../temp/event_study_panel_b.dta ../../temp/event_study_moments.dta ../../temp/revenue_models.ster bloom_autonomy_analysis.log table/atet_owner.tex table/atet_manager.tex

# Final reporting pipeline
report: paper.pdf figure/figure1.pdf figure/figure2.pdf figure/figure3.pdf

extract: ../../output/extract/manager_changes_2015.dta ../../output/extract/connected_managers.dta

# Event study figures pipeline
event_study: $(foreach sample,$(SAMPLES),$(foreach outcome,$(OUTCOMES),data/$(sample)_$(outcome).csv))

# =============================================================================
# Data wrangling
# =============================================================================

# Process raw balance sheet data
../../temp/balance.dta: ../../lib/create/balance.do ../../input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	cd ../.. && $(STATA) lib/create/balance.do

# Process CEO panel data
../../temp/ceo-panel.dta: ../../lib/create/ceo-panel.do ../../input/ceo-panel/ceo-panel.dta
	cd ../.. && $(STATA) lib/create/ceo-panel.do

# Create analysis sample
../../temp/analysis-sample.dta: ../../lib/create/analysis-sample.do ../../temp/unfiltered.dta ../../lib/util/filter.do
	cd ../.. && $(STATA) lib/create/analysis-sample.do

# Generate placebo CEO transitions
../../temp/placebo_%.dta: ../../lib/create/event_study_sample.do ../../temp/surplus.dta ../../temp/analysis-sample.dta ../../temp/manager_value.dta 
	cd ../.. && $(STATA) lib/create/event_study_sample.do $*

# Extract firm-manager edgelist
../../temp/edgelist.csv: ../../lib/create/edgelist.do ../../temp/analysis-sample.dta
	cd ../.. && $(STATA) lib/create/edgelist.do

# Find largest connected component of managers
../../temp/large_component_managers.csv: ../../lib/create/connected_component.jl ../../temp/edgelist.csv
	cd ../.. && $(JULIA) lib/create/connected_component.jl

# Create unfiltered dataset for table creation
../../temp/unfiltered.dta: ../../lib/create/unfiltered.do ../../temp/balance.dta ../../temp/ceo-panel.dta $(UTILS)
	cd ../.. && $(STATA) lib/create/unfiltered.do

# =============================================================================
# Statistical analysis
# =============================================================================

# Estimate revenue function and residualize surplus
../../temp/surplus.dta: ../../lib/estimate/surplus.do ../../temp/analysis-sample.dta
	cd ../.. && $(STATA) lib/estimate/surplus.do

# Estimate manager fixed effects and variance decomposition components
../../temp/manager_value.dta figure/manager_skill_within.pdf figure/manager_skill_connected.pdf: ../../lib/estimate/manager_value.do ../../temp/surplus.dta ../../temp/large_component_managers.csv ../../lib/create/network-sample.do
	mkdir -p figure
	cd ../.. && $(STATA) lib/estimate/manager_value.do

# Function to generate the rule for each outcome
define OUTCOME_RULE
data/%_$(1).csv: ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../temp/surplus.dta ../../temp/analysis-sample.dta ../../temp/manager_value.dta ../../temp/placebo_%.dta
	mkdir -p data
	ln -sf ../../temp/placebo_$$*.dta data/placebo_$$*.dta
	cd ../.. && $$(STATA) "papers/application/lib/estimate/event_study.do $$* $(1)"
	rm -f data/placebo_$$*.dta
endef

# Generate rules for each outcome
$(foreach outcome,$(OUTCOMES),$(eval $(call OUTCOME_RULE,$(outcome))))

# Revenue function estimation results - saves all model estimates
../../temp/revenue_models.ster: ../../lib/estimate/revenue_function.do ../../temp/analysis-sample.dta ../../temp/large_component_managers.csv ../../lib/create/network-sample.do
	cd ../.. && $(STATA) lib/estimate/revenue_function.do

# Bloom et al. (2012) autonomy analysis - supporting evidence
bloom_autonomy_analysis.log: ../../lib/estimate/bloom_autonomy_analysis.do ../../input/bloom-et-al-2012/replication.dta
	cd ../.. && $(STATA) lib/estimate/bloom_autonomy_analysis.do


# =============================================================================
# Exhibits (tables and figures)
# =============================================================================

# Table 1: Sample distribution over time
table/table1_panelAB.tex: src/exhibit/table1.do ../../temp/unfiltered.dta ../../temp/analysis-sample.dta ../../temp/large_component_managers.csv
	mkdir -p table
	cd ../.. && $(STATA) papers/application/src/exhibit/table1.do

# Table 2: CEO patterns and spell length
table/table2_panelA.tex table/table2_panelB.tex: src/exhibit/table2.do ../../temp/analysis-sample.dta
	mkdir -p table
	cd ../.. && $(STATA) papers/application/src/exhibit/table2.do

# Table 3: Revenue function estimation results
table/table3.tex: src/exhibit/table3.do ../../temp/revenue_models.ster ../../temp/analysis-sample.dta ../../temp/large_component_managers.csv ../../lib/create/network-sample.do
	mkdir -p table
	cd ../.. && $(STATA) papers/application/src/exhibit/table3.do

# Table A0: Bloom et al. (2012) autonomy analysis
table/tableA0.tex: src/exhibit/tableA0.do ../../input/bloom-et-al-2012/replication.dta
	mkdir -p table
	cd ../.. && $(STATA) papers/application/src/exhibit/tableA0.do

# Table A1: Industry-level summary statistics (moved to appendix)
table/tableA1.tex: src/exhibit/tableA1.do ../../temp/unfiltered.dta ../../temp/analysis-sample.dta $(UTILS)
	mkdir -p table
	cd ../.. && $(STATA) papers/application/src/exhibit/tableA1.do

# ATET tables
table/atet_owner.tex table/atet_manager.tex: ../../lib/estimate/anova.do ../../temp/surplus.dta ../../temp/analysis-sample.dta
	mkdir -p table
	cd ../.. && $(STATA) lib/estimate/anova.do

# =============================================================================
# Figures
# =============================================================================

# Figure 1: Main event study figure
figure/figure1.pdf: src/exhibit/figure1.do data/fnd2non_TFP.csv data/non2non_TFP.csv data/full_TFP.csv data/post2004_TFP.csv
	mkdir -p figure
	cd ../.. && $(STATA) papers/application/src/exhibit/figure1.do

# Figure 2: Event study by CEO transition type (4 panels)  
figure/figure2.pdf: src/exhibit/figure2.do data/fnd2non_TFP.csv data/non2non_TFP.csv data/full_TFP.csv data/post2004_TFP.csv
	mkdir -p figure
	cd ../.. && $(STATA) papers/application/src/exhibit/figure2.do

# Figure 3: Event study outcomes (Capital, Intangibles, Materials, Wagebill)
figure/figure3.pdf: src/exhibit/figure3.do data/full_lnK.csv data/full_has_intangible.csv data/full_lnM.csv data/full_lnWL.csv
	mkdir -p figure
	cd ../.. && $(STATA) papers/application/src/exhibit/figure3.do

# =============================================================================
# LaTeX compilation
# =============================================================================

# Compile final paper
paper.pdf: paper.tex ../../lib/references.bib table/table1_panelAB.tex table/table2_panelA.tex table/table2_panelB.tex table/table3.tex table/tableA0.tex table/tableA1.tex table/tableA3.tex table/tableA4.tex figure/manager_skill_within.pdf figure/manager_skill_connected.pdf figure/figure1.pdf figure/figure2.pdf figure/figure3.pdf
	$(LATEX) paper.tex && bibtex paper && $(LATEX) paper.tex && $(LATEX) paper.tex

# =============================================================================
# Optional extracts and tests
# =============================================================================

# Data extracts for external sharing
../../output/extract/manager_changes_2015.dta ../../output/extract/connected_managers.dta: ../../lib/create/extract.do ../../temp/manager_value.dta ../../temp/surplus.dta ../../temp/analysis-sample.dta ../../input/ceo-panel/ceo-panel.dta
	mkdir -p ../../output/extract
	cd ../.. && $(STATA) lib/create/extract.do

# Network analysis tests
../../output/test/test_paths.csv: ../../lib/test/test_network.jl ../../temp/edgelist.csv ../../temp/large_component_managers.csv
	mkdir -p ../../output/test
	cd ../.. && $(JULIA) lib/test/test_network.jl 1000 10

# Balance estimation (alternative analysis)
balance.log: ../../lib/estimate/balance.do ../../temp/analysis-sample.dta ../../lib/create/network-sample.do
	cd ../.. && $(STATA) lib/estimate/balance.do

# Test placebo analysis
../../output/test/placebo_test.log: ../../lib/test/placebo.do ../../output/test/placebo.dta
	mkdir -p ../../output/test
	cd ../.. && $(STATA) lib/test/placebo.do

# =============================================================================
# Utilities
# =============================================================================

# Install Stata packages
install.log: ../../lib/util/install.do
	cd ../.. && $(STATA) lib/util/install.do

# =============================================================================
# Extract files from other branches/commits
# =============================================================================

# Pattern rule to extract any file from any commit
# Usage: make branches/main/code/exhibit/table1.do
#        make branches/abc123f/output/paper.tex
branches/%:
	@mkdir -p $(dir $@)
	@commit=$$(echo $* | cut -d/ -f1); \
	filepath=$$(echo $* | cut -d/ -f2-); \
	cd ../.. && git show $$commit:$$filepath > papers/application/$@ 2>/dev/null || (echo "Error: Could not extract $$filepath from $$commit" && rm -f $@ && exit 1)
	@echo "Extracted: $@"

../../temp/event_study_panel_c.dta: branches/1b375e4f6f099795942847f93be0d5ee68efee67/output/event_study_panel_b.dta
	@cp $< $@

../../temp/event_study_panel_d.dta: branches/6ca0e95a270eda23824347489ceb1f3964f75695/output/event_study_panel_b.dta
	@cp $< $@
