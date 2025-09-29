# =============================================================================
# CEO Value Research Project Makefile
# Implements novel placebo-controlled event study design
# =============================================================================

# Tool definitions
STATA := stata-mp -b do
JULIA := julia --project=.
LATEX := pdflatex
PANDOC := pandoc
UTILS := $(wildcard code/util/*.do)

SAMPLES := full fnd2non non2non post2004
OUTCOMES := TFP lnK lnWL lnM has_intangible

# Commit hashes for reproducible file extraction
# Update these when you need specific versions of files from other branches
COMMIT_MAIN := HEAD  # Update with specific hash when needed, e.g., abc123f
COMMIT_PLACEBO := placebo  # Update with specific hash when needed
COMMIT_EXPERIMENT := experiment/preferred  # Update with specific hash when needed

# Define costly intermediate files to preserve
PRECIOUS_FILES := temp/balance.dta temp/ceo-panel.dta temp/unfiltered.dta \
                  temp/analysis-sample.dta temp/placebo.dta temp/edgelist.csv \
                  temp/large_component_managers.csv temp/surplus.dta \
                  temp/manager_value.dta temp/revenue_models.ster $(foreach sample,$(SAMPLES),temp/placebo_$(sample).dta)

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
data: temp/unfiltered.dta temp/analysis-sample.dta temp/placebo.dta temp/large_component_managers.csv

# Statistical analysis pipeline  
analysis: temp/surplus.dta temp/manager_value.dta temp/event_study_panel_a.dta temp/event_study_panel_b.dta temp/event_study_moments.dta temp/revenue_models.ster bloom_autonomy_analysis.log output/table/atet_owner.tex output/table/atet_manager.tex

# Final reporting pipeline
report: output/paper.pdf output/slides60.pdf output/figure/figure1.pdf output/figure/figure3.pdf

extract: output/extract/manager_changes_2015.dta output/extract/connected_managers.dta

# Event study figures pipeline
event_study: $(foreach sample,$(SAMPLES),$(foreach outcome,$(OUTCOMES),output/event_study/$(sample)_$(outcome).csv))

# =============================================================================
# Data wrangling
# =============================================================================

# Process raw balance sheet data
temp/balance.dta: code/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

# Process CEO panel data
temp/ceo-panel.dta: code/create/ceo-panel.do input/ceo-panel/ceo-panel.dta
	$(STATA) $<

# Create analysis sample
temp/analysis-sample.dta: code/create/analysis-sample.do temp/unfiltered.dta code/util/filter.do
	$(STATA) $<

# Generate placebo CEO transitions
temp/placebo_%.dta: code/create/event_study_sample.do temp/surplus.dta temp/analysis-sample.dta temp/manager_value.dta 
	$(STATA) $< $*

# Extract firm-manager edgelist
temp/edgelist.csv: code/create/edgelist.do temp/analysis-sample.dta
	$(STATA) $<

# Find largest connected component of managers
temp/large_component_managers.csv: code/create/connected_component.jl temp/edgelist.csv
	$(JULIA) $<

# Create unfiltered dataset for table creation
temp/unfiltered.dta: code/create/unfiltered.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
	$(STATA) $<

# =============================================================================
# Statistical analysis
# =============================================================================

# Estimate revenue function and residualize surplus
temp/surplus.dta: code/estimate/surplus.do temp/analysis-sample.dta
	$(STATA) $<

# Estimate manager fixed effects and variance decomposition components
temp/manager_value.dta output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf: code/estimate/manager_value.do temp/surplus.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<

# Function to generate the rule for each outcome
define OUTCOME_RULE
output/event_study/%_$(1).csv: code/estimate/event_study.do code/estimate/setup_event_study.do temp/surplus.dta temp/analysis-sample.dta temp/manager_value.dta temp/placebo_%.dta
	mkdir -p $$(dir $$@)
	$$(STATA) $$< $$* $(1)
endef

# Generate rules for each outcome
$(foreach outcome,$(OUTCOMES),$(eval $(call OUTCOME_RULE,$(outcome))))

# Revenue function estimation results - saves all model estimates
temp/revenue_models.ster: code/estimate/revenue_function.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	$(STATA) $<

# Bloom et al. (2012) autonomy analysis - supporting evidence
bloom_autonomy_analysis.log: code/estimate/bloom_autonomy_analysis.do input/bloom-et-al-2012/replication.dta
	$(STATA) $<


# =============================================================================
# Exhibits (tables and figures)
# =============================================================================

# Table 1: Sample distribution over time
output/table/table1.tex: code/exhibit/table1.do temp/unfiltered.dta temp/analysis-sample.dta temp/large_component_managers.csv
	mkdir -p $(dir $@)
	$(STATA) $<

# Table A0: Bloom et al. (2012) autonomy analysis
output/table/tableA0.tex: code/exhibit/tableA0.do input/bloom-et-al-2012/replication.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Table A1: Industry-level summary statistics (moved to appendix)
output/table/tableA1.tex: code/exhibit/tableA1.do temp/unfiltered.dta temp/analysis-sample.dta $(UTILS)
	mkdir -p $(dir $@)
	$(STATA) $<

# Table 3: Revenue function estimation results
output/table/table3.tex: code/exhibit/table3.do temp/revenue_models.ster temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<


# =============================================================================
# LaTeX compilation
# =============================================================================

# Compile final paper
output/paper.pdf: output/paper.tex output/table/table1.tex output/table/table2_panelA.tex output/table/table2_panelB.tex output/table/table3.tex output/table/tableA0.tex output/table/tableA1.tex output/table/atet_owner.tex output/table/atet_manager.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/figure/figure1.pdf output/figure/figure3.pdf output/references.bib
	cd output && $(LATEX) paper.tex && bibtex paper && $(LATEX) paper.tex && $(LATEX) paper.tex

# Compile presentation slides
output/slides60.pdf: output/slides60.md output/preamble-slides.tex output/table/table1.tex output/table/table2_panelA.tex output/table/table2_panelB.tex output/table/table3.tex output/table/tableA0.tex output/table/tableA1.tex output/table/atet_owner.tex output/table/atet_manager.tex output/figure/manager_skill_connected.pdf output/figure/figure1.pdf output/figure/figure3.pdf
	cd output && $(PANDOC) slides60.md -t beamer --slide-level 2 -H preamble-slides.tex -o slides60.pdf

# Figure 1: Event study by CEO transition type (4 panels)  
output/figure/figure1.pdf: code/exhibit/figure1.do output/event_study/fnd2non_TFP.csv output/event_study/non2non_TFP.csv output/event_study/full_TFP.csv output/event_study/post2004_TFP.csv code/exhibit/event_study.do
	mkdir -p $(dir $@)
	$(STATA) $<

# Figure 3: Event study outcomes (Capital, Intangibles, Materials, Wagebill)
output/figure/figure3.pdf: code/exhibit/figure3.do output/event_study/full_lnK.csv output/event_study/full_has_intangible.csv output/event_study/full_lnM.csv output/event_study/full_lnWL.csv code/exhibit/event_study.do
	mkdir -p $(dir $@)
	$(STATA) $<

# =============================================================================
# Optional extracts and tests
# =============================================================================

# Data extracts for external sharing
output/extract/manager_changes_2015.dta output/extract/connected_managers.dta: code/create/extract.do temp/manager_value.dta temp/surplus.dta temp/analysis-sample.dta input/ceo-panel/ceo-panel.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Network analysis tests
output/test/test_paths.csv: code/test/test_network.jl temp/edgelist.csv temp/large_component_managers.csv
	mkdir -p $(dir $@)
	$(JULIA) $< 1000 10

# Balance estimation (alternative analysis)
balance.log: code/estimate/balance.do temp/analysis-sample.dta code/create/network-sample.do
	$(STATA) $<

# Test placebo analysis
output/test/placebo_test.log: code/test/placebo.do output/test/placebo.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# =============================================================================
# Utilities
# =============================================================================

# Install Stata packages
install.log: code/util/install.do
	$(STATA) $<

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
	git show $$commit:$$filepath > $@ 2>/dev/null || (echo "Error: Could not extract $$filepath from $$commit" && rm -f $@ && exit 1)
	@echo "Extracted: $@"

temp/event_study_panel_c.dta:  branches/1b375e4f6f099795942847f93be0d5ee68efee67/output/event_study_panel_b.dta
	@cp $< $@

temp/event_study_panel_d.dta:  branches/6ca0e95a270eda23824347489ceb1f3964f75695/output/event_study_panel_b.dta
	@cp $< $@
