# =============================================================================
# CEO Value Research Project Makefile
# Implements novel placebo-controlled event study design
# =============================================================================

# Tool definitions
STATA := stata -b do
JULIA := julia --project=.
LATEX := pdflatex
UTILS := $(wildcard code/util/*.do)

# =============================================================================
# Main targets
# =============================================================================

.PHONY: all clean install data analysis report

# Complete workflow: data → analysis → report
all: report

# Install dependencies and setup
install: install.log

# Data wrangling pipeline
data: temp/analysis-sample.dta temp/placebo.dta temp/large_component_managers.csv

# Statistical analysis pipeline  
analysis: temp/surplus.dta temp/manager_value.dta temp/event_study_panel_a.dta temp/event_study_panel_b.dta

# Final reporting pipeline
report: output/paper.pdf

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
temp/analysis-sample.dta: code/create/analysis-sample.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
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

# =============================================================================
# Statistical analysis
# =============================================================================

# Estimate revenue function and residualize surplus
temp/surplus.dta: code/estimate/surplus.do temp/analysis-sample.dta
	$(STATA) $<

# Estimate manager fixed effects
temp/manager_value.dta output/table/manager_effects.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf: code/estimate/manager_value.do temp/surplus.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<

# Run placebo-controlled event study
temp/event_study_panel_a.dta temp/event_study_panel_b.dta output/figure/manager_skill_correlation.pdf output/test/event_study.dta: code/estimate/event_study.do temp/manager_value.dta temp/analysis-sample.dta temp/placebo.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Revenue function estimation results
output/table/revenue_function.tex output/table/revenue_sectors.tex output/table/revenue_controls.tex: code/estimate/revenue_function.do code/estimate/exit.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<

# =============================================================================
# Exhibits (tables and figures)
# =============================================================================

# Table 1: Sample distribution over time
output/table/table1.tex: code/exhibit/table1.do temp/analysis-sample.dta temp/balance.dta temp/large_component_managers.csv
	mkdir -p $(dir $@)
	$(STATA) $<

# Table 2: Industry-level summary statistics
output/table/table2.tex: code/exhibit/table2.do temp/balance.dta temp/analysis-sample.dta $(UTILS)
	mkdir -p $(dir $@)
	$(STATA) $<

# Table 3: Network statistics
output/table/table3.tex: code/exhibit/table3.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<

# Table 6: CEO patterns and spell length analysis
output/table/table6.tex: code/exhibit/table6.do temp/analysis-sample.dta temp/placebo.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Figure 1: Event study results
output/figure/event_study.pdf: code/exhibit/figure1.do temp/event_study_panel_a.dta temp/event_study_panel_b.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# =============================================================================
# LaTeX compilation
# =============================================================================

# Compile final paper
output/paper.pdf: output/paper.tex output/table/table1.tex output/table/table2.tex output/table/table3.tex output/table/table6.tex output/table/revenue_function.tex output/table/revenue_sectors.tex output/table/manager_effects.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/figure/manager_skill_correlation.pdf output/figure/event_study.pdf output/references.bib
	cd output && $(LATEX) paper.tex && bibtex paper && $(LATEX) paper.tex && $(LATEX) paper.tex

# =============================================================================
# Optional extracts and tests
# =============================================================================

# Data extracts for external sharing
output/extract/2022_values.dta output/extract/manager_changes_2015.dta output/extract/connected_managers.dta: code/create/extract.do temp/manager_value.dta temp/surplus.dta temp/analysis-sample.dta input/ceo-panel/ceo-panel.dta
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

# Clean temporary and output files
clean:
	rm -rf temp/* output/*
