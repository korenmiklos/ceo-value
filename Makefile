# =============================================================================
# CEO Value Research Project Makefile
# Implements novel placebo-controlled event study design
# =============================================================================

# Tool definitions
STATA := stata -b do
JULIA := julia --project=.
LATEX := pdflatex
PANDOC := pandoc
UTILS := $(wildcard code/util/*.do)

# Define costly intermediate files to preserve
PRECIOUS_FILES := temp/balance.dta temp/ceo-panel.dta temp/unfiltered.dta \
                  temp/analysis-sample.dta temp/placebo.dta temp/edgelist.csv \
                  temp/large_component_managers.csv temp/surplus.dta \
                  temp/manager_value.dta temp/revenue_models.ster \
                  output/event_study_panel_b.dta

# Mark these files as PRECIOUS so make won't delete them
.PRECIOUS: $(PRECIOUS_FILES)

# =============================================================================
# Main targets
# =============================================================================

.PHONY: all install data analysis report

# Complete workflow: data → analysis → report
all: report

# Install dependencies and setup
install: install.log

# Data wrangling pipeline
data: temp/unfiltered.dta temp/analysis-sample.dta temp/placebo.dta temp/large_component_managers.csv

# Statistical analysis pipeline  
analysis: temp/surplus.dta temp/manager_value.dta output/event_study_panel_b.dta temp/revenue_models.ster bloom_autonomy_analysis.log output/table/atet_owner.tex output/table/atet_manager.tex

# Final reporting pipeline
report: output/paper.pdf output/slides60.pdf

extract: output/extract/manager_changes_2015.dta output/extract/connected_managers.dta

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
temp/placebo.dta: code/create/placebo.do temp/analysis-sample.dta
	$(STATA) $<

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

# Run placebo-controlled event study
output/event_study_panel_b.dta: code/estimate/event_study.do code/estimate/setup_event_study.do temp/surplus.dta temp/analysis-sample.dta temp/manager_value.dta temp/placebo.dta
	mkdir -p temp output
	$(STATA) $<

# Revenue function estimation results - saves all model estimates
temp/revenue_models.ster: code/estimate/revenue_function.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	$(STATA) $<

# Bloom et al. (2012) autonomy analysis - supporting evidence
bloom_autonomy_analysis.log: code/estimate/bloom_autonomy_analysis.do input/bloom-et-al-2012/replication.dta
	$(STATA) $<

# Event study outcomes analysis - heterogeneous treatment effects
output/table/atet_owner.tex output/table/atet_manager.tex output/figure/event_study_owner_controlled.pdf output/figure/event_study_manager_controlled.pdf: code/estimate/event_study_outcomes.do code/estimate/setup_event_study.do temp/surplus.dta temp/analysis-sample.dta temp/manager_value.dta temp/placebo.dta
	mkdir -p output/table output/figure
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

# Table 2: CEO patterns and spell length analysis (two panels) - moved from Table 6
output/table/table2_panelA.tex output/table/table2_panelB.tex: code/exhibit/table2.do temp/unfiltered.dta temp/placebo.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Table 4: Manager skill by sector and ownership (two panels)
output/table/table4_panelA.tex output/table/table4_panelB.tex: code/exhibit/table4.do temp/analysis-sample.dta temp/manager_value.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Figure 1: Panel C - Sample Period 2004-2022 (placebo-controlled event study)
output/event_study_panel_c.gph: code/exhibit/figure1.do output/event_study_panel_b.dta
	mkdir -p output
	$(STATA) $<

# =============================================================================
# LaTeX compilation
# =============================================================================

# Compile final paper
output/paper.pdf: output/paper.tex output/table/table1.tex output/table/table2_panelA.tex output/table/table2_panelB.tex output/table/table3.tex output/table/table4_panelA.tex output/table/table4_panelB.tex output/table/tableA0.tex output/table/tableA1.tex output/table/atet_owner.tex output/table/atet_manager.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/event_study_panel_c.gph output/references.bib
	cd output && $(LATEX) paper.tex && bibtex paper && $(LATEX) paper.tex && $(LATEX) paper.tex

# Compile presentation slides
output/slides60.pdf: output/slides60.md output/preamble-slides.tex output/table/table1.tex output/table/table2_panelA.tex output/table/table2_panelB.tex output/table/table3.tex output/table/tableA0.tex output/table/tableA1.tex output/table/atet_owner.tex output/table/atet_manager.tex output/figure/manager_skill_connected.pdf output/event_study_panel_c.gph output/figure/event_study_owner_controlled.pdf output/figure/event_study_manager_controlled.pdf
	cd output && $(PANDOC) slides60.md -t beamer --slide-level 2 -H preamble-slides.tex -o slides60.pdf

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

# =============================================================================
# Utilities
# =============================================================================

# Install Stata packages
install.log: code/util/install.do
	$(STATA) $<
