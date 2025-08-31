# =============================================================================
# CEO Value Research Project Makefile
# Implements novel placebo-controlled event study design
# 
# Recent improvements:
# - Automated Python virtual environment setup
# - Julia package installation and dependency management
# - Automated LaTeX dependency management (apacite package)
# - Enhanced error handling for bibliography compilation
# - Comprehensive dependency status checking
# - Added comprehensive help system
# - Separate targets for data extraction and testing
# =============================================================================

# Tool definitions
STATA := stata-mp -b do
JULIA := julia --project=.
LATEX := pdflatex
UTILS := $(wildcard code/util/*.do)

# =============================================================================
# Main targets
# =============================================================================

.PHONY: all clean clean-all clean-env install data analysis report setup-env setup-julia setup-latex setup-stata extract test status help

# Display help information
help:
	@echo "CEO Value Research Project Makefile"
	@echo "=================================="
	@echo ""
	@echo "Main targets:"
	@echo "  all        - Complete workflow: data → analysis → tables → figures → test"
	@echo "  install    - Install all dependencies (Python, Julia, Stata, LaTeX)"
	@echo "  data       - Run data wrangling pipeline"
	@echo "  analysis   - Run statistical analysis pipeline"
	@echo "  tables     - Generate all LaTeX tables"
	@echo "  figures    - Generate all PDF figures"
	@echo "  test       - Generate test outputs and validation files"
	@echo "  report     - Generate final paper (PDF) - requires paper.tex and references.bib"
	@echo ""
	@echo "Setup targets:"
	@echo "  setup-env  - Create Python virtual environment"
	@echo "  setup-julia- Install Julia packages"
	@echo "  setup-latex- Setup LaTeX dependencies (apacite package)"
	@echo "  setup-stata- Install Stata packages"
	@echo "  update-stata- Update/reinstall Stata packages"
	@echo ""
	@echo "Additional targets:"
	@echo "  extract    - Extract data for external sharing"
	@echo "  test       - Run network analysis tests"
	@echo "  status     - Show status of all dependencies"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean      - Remove temporary files (preserves output)"
	@echo "  clean-all  - Remove all generated files including output"
	@echo "  clean-env  - Remove Python environment only"
	@echo "  help       - Show this help message"

# Complete workflow: data → analysis → report
all: analysis tables figures test
	@echo ""
	@echo "✓ Data processing and analysis complete!"
	@echo "✓ All tables and figures generated in output/"
	@echo "✓ Test files generated in output/test/"
	@echo ""
	@echo "Paper components available:"
	@if [ -f output/paper.tex ]; then echo "  ✓ LaTeX source file (output/paper.tex)"; else echo "  ✗ Missing output/paper.tex"; fi
	@if [ -f output/references.bib ]; then echo "  ✓ Bibliography file (output/references.bib)"; else echo "  ✗ Missing output/references.bib"; fi
	@if [ -f output/paper.pdf ]; then echo "  ✓ Final PDF already exists (output/paper.pdf)"; else echo "  → Run 'make report' to generate output/paper.pdf"; fi
	@echo ""

# Install all dependencies and setup
install: setup-env setup-julia setup-stata setup-latex
	@echo "All dependencies installed successfully!"

# Setup Python virtual environment
setup-env: env/bin/activate
	@echo "Python environment ready"

env/bin/activate:
	@echo "Creating Python virtual environment..."
	python3 -m venv env
	env/bin/pip install --upgrade pip
	@if [ -f requirements.txt ]; then \
		echo "Installing Python packages from requirements.txt..."; \
		env/bin/pip install -r requirements.txt; \
	else \
		echo "No requirements.txt found, skipping package installation"; \
	fi
	@echo "Python virtual environment created in ./env/"
	@echo "To activate: source env/bin/activate"

# Setup Julia packages
setup-julia: Manifest.toml
	@echo "Installing Julia packages..."
	$(JULIA) -e "using Pkg; Pkg.instantiate()"
	@echo "Julia packages installed successfully"

# Setup Stata packages  
setup-stata: install.log
	@echo "Stata packages ready"

# Show status of all dependencies
status:
	@echo "Dependency Status Check"
	@echo "======================"
	@echo -n "Python environment: "
	@if [ -d env ]; then echo "✓ Created"; else echo "✗ Missing (run 'make setup-env')"; fi
	@echo -n "Julia packages: "
	@if [ -f Manifest.toml ]; then echo "✓ Available"; else echo "✗ Missing Project.toml"; fi
	@echo -n "Stata packages: "
	@if [ -f install.log ]; then echo "✓ Installed"; else echo "✗ Not installed (run 'make setup-stata')"; fi
	@echo -n "LaTeX apacite: "
	@if [ -f apacite.sty ]; then echo "✓ Available"; else echo "✗ Missing (run 'make setup-latex')"; fi
	@echo ""

# Data wrangling pipeline
data: temp/unfiltered.dta temp/analysis-sample.dta temp/placebo.dta temp/large_component_managers.csv

# Statistical analysis pipeline  
analysis: temp/surplus.dta temp/manager_value.dta temp/event_study_panel_a.dta temp/event_study_panel_b.dta temp/revenue_models.ster

# Generate all tables (core tables that are actually generated)
tables: output/table/table1.tex output/table/table2_panelA.tex output/table/table2_panelB.tex output/table/table3.tex output/table/table4a.tex output/table/tableA1.tex output/table/outcome_rotation.tex output/table/coverage_rationale.tex output/table/missingness_patterns.tex

# Additional tables (if they exist or can be generated)
tables-extra: 
	@echo "Checking for additional table generation scripts..."
	@if [ -f code/exhibit/table2_extra.do ]; then $(STATA) code/exhibit/table2_extra.do; fi
	@if [ -f code/exhibit/table6.do ]; then $(STATA) code/exhibit/table6.do; fi
	@echo "Additional table generation complete (if scripts exist)"

# All tables including extra ones
tables-all: tables tables-extra

# Generate all figures  
figures: output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/figure/event_study.pdf

# Generate test outputs
test: output/test/test_paths.csv

# Final reporting pipeline (requires manual paper.tex and references.bib)
report: output/paper.pdf

extract: output/extract/manager_changes_2015.dta output/extract/connected_managers.dta
report: output/paper.pdf

extract: output/extract/manager_changes_2015.dta output/extract/connected_managers.dta

# =============================================================================
# Data wrangling
# =============================================================================

# Process raw balance sheet data
temp/balance.dta: code/create/balance.do input/merleg-LTS-2023-patch/balance/balance_sheet_80_22.dta
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
temp/manager_value.dta temp/within_firm.dta temp/cross_section.dta output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf: code/estimate/manager_value.do temp/surplus.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p $(dir $@)
	$(STATA) $<

# Run placebo-controlled event study
temp/event_study_panel_a.dta temp/event_study_panel_b.dta output/event_study.txt: code/estimate/event_study.do temp/manager_value.dta temp/analysis-sample.dta temp/placebo.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Revenue function estimation results - saves all model estimates
temp/revenue_models.ster: code/estimate/revenue_function.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	$(STATA) $<

# =============================================================================
# Exhibits (tables and figures)
# =============================================================================

# Table 1: Sample distribution over time
output/table/table1.tex: code/exhibit/table1.do temp/unfiltered.dta temp/analysis-sample.dta temp/large_component_managers.csv
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

# Table 4: Variance decomposition
output/table/table4a.tex: code/exhibit/table4.do temp/within_firm.dta temp/cross_section.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# NEW TABLES FOR ISSUE #10

# Outcome rotation analysis
output/table/outcome_rotation.tex output/table/outcome_sample_sizes.tex: code/estimate/outcome_rotation.do temp/analysis-sample.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Missingness analysis
output/table/missingness_patterns.tex output/table/coverage_rationale.tex: code/estimate/missingness_analysis.do temp/analysis-sample.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# Exhibit reorganization plan
temp/reorganization_plan.txt: code/exhibit/reorganize_exhibits.do
	$(STATA) $<

# Figure 1: Event study results
output/figure/event_study.pdf: code/exhibit/figure1.do temp/event_study_panel_a.dta temp/event_study_panel_b.dta
	mkdir -p $(dir $@)
	$(STATA) $<

# =============================================================================
# LaTeX compilation
# =============================================================================

# Ensure apacite package files are available
output/apacite.sty output/apacite.bst: apacite.sty
	mkdir -p output
	cp apacite.sty output/
	@if [ -f apacite.bst ]; then cp apacite.bst output/; fi
	@if [ ! -f output/apacite.bst ]; then \
		echo "Generating apacite.bst..."; \
		wget -q https://ctan.org/tex-archive/biblio/bibtex/contrib/apacite.zip -O /tmp/apacite.zip && \
		cd /tmp && unzip -q apacite.zip && latex apacite.ins > /dev/null 2>&1 && \
		cp apacite.bst $(CURDIR)/output/ && \
		rm -rf /tmp/apacite* ; \
	fi

# Compile final paper
output/paper.pdf: output/paper.tex output/table/table1.tex output/table/table2_panelA.tex output/table/table2_panelB.tex output/table/table3.tex output/table/table4a.tex output/table/tableA1.tex output/table/outcome_rotation.tex output/table/coverage_rationale.tex output/table/missingness_patterns.tex output/table/outcome_sample_sizes.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/figure/event_study.pdf output/references.bib output/apacite.sty output/apacite.bst
	@if [ ! -f output/paper.tex ]; then \
		echo "Error: output/paper.tex not found. Please create the LaTeX source file."; \
		exit 1; \
	fi
	@if [ ! -f output/references.bib ]; then \
		echo "Error: output/references.bib not found. Please create the bibliography file."; \
		exit 1; \
	fi
	cd output && $(LATEX) paper.tex && bibtex paper && $(LATEX) paper.tex && $(LATEX) paper.tex

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

# Update Stata packages (force reinstall)
update-stata: 
	@echo "Updating Stata packages..."
	$(STATA) code/util/install.do
	@echo "Stata packages updated"

# Setup LaTeX dependencies (apacite package)
setup-latex: apacite.sty
	@echo "LaTeX dependencies are ready"

apacite.sty:
	@echo "Setting up apacite LaTeX package..."
	wget -q https://ctan.org/tex-archive/biblio/bibtex/contrib/apacite.zip
	unzip -q apacite.zip
	cd apacite && latex apacite.ins > /dev/null 2>&1
	cp apacite/apacite.sty .
	cp apacite/apacite.bst .
	rm -rf apacite apacite.zip
	@echo "Apacite package setup complete"

# Clean temporary files only (preserves output and environments)
clean:
	rm -rf temp/*

# Clean everything including output, environments, and LaTeX dependencies
clean-all: clean
	rm -rf output/*
	rm -f apacite.sty apacite.bst
	rm -rf env/

# Clean only environments (useful for refreshing dependencies)
clean-env:
	rm -rf env/
	@echo "Python environment removed. Run 'make setup-env' to recreate."
