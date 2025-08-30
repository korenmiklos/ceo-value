# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an academic research project implementing a novel placebo-controlled event study design to estimate the causal effect of CEO quality on firm performance. Using comprehensive administrative data from Hungarian firms (1992-2022), the project separates true managerial effects from spurious correlations by comparing actual CEO transitions to carefully constructed placebo transitions. The analysis uses Stata for data processing and econometric estimation, Julia for network analysis, and LaTeX for paper compilation.

## Core Commands

### Build the entire project
```bash
make all
```
This runs all Stata scripts in dependency order and compiles the final PDF, including all tables and figures.

### Individual components
```bash
# Process balance sheet data
stata -b do code/create/balance.do

# Process CEO panel data  
stata -b do code/create/ceo-panel.do

# Create analysis sample
stata -b do code/create/analysis-sample.do

# Generate placebo CEO transitions
stata -b do code/create/placebo.do

# Extract firm-manager edgelist
stata -b do code/create/edgelist.do

# Find largest connected component of managers
julia --project=. code/create/connected_component.jl

# Generate exhibit tables
stata -b do code/exhibit/table1.do
stata -b do code/exhibit/table2.do
stata -b do code/exhibit/table3.do
stata -b do code/exhibit/table4.do
stata -b do code/exhibit/tableA1.do

# Run econometric analysis
stata -b do code/estimate/surplus.do
stata -b do code/estimate/revenue_function.do
stata -b do code/estimate/manager_value.do

# Run placebo-controlled event study (estimation)
stata -b do code/estimate/event_study.do

# Create event study figure
stata -b do code/exhibit/figure1.do

# Compile LaTeX document
cd output && pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
```

### Manual execution (if Make unavailable)
```bash
# Process data with Stata
stata -b do code/create/balance.do
stata -b do code/create/ceo-panel.do
stata -b do code/create/unfiltered.do
stata -b do code/create/analysis-sample.do
stata -b do code/create/placebo.do
stata -b do code/create/edgelist.do

# Run network analysis with Julia
julia --project=. code/create/connected_component.jl

# Generate econometric analysis
stata -b do code/estimate/surplus.do
stata -b do code/estimate/revenue_function.do
stata -b do code/estimate/manager_value.do

# Run event study
stata -b do code/estimate/event_study.do

# Generate exhibits/tables
stata -b do code/exhibit/table1.do
stata -b do code/exhibit/table2.do
stata -b do code/exhibit/table3.do
stata -b do code/exhibit/table4.do
stata -b do code/exhibit/tableA1.do
stata -b do code/exhibit/figure1.do

# Create data extracts (optional)
stata -b do code/create/extract.do
```
Then compile the LaTeX document:
```bash
cd output && pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
```

## Architecture

### Data Pipeline
1. **Raw Data** (`input/`): Proprietary Hungarian administrative datasets
   - `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta`: Balance sheet data
   - `input/ceo-panel/ceo-panel.dta`: CEO registry data

2. **Processing** (`code/create/`): Stata scripts that clean and merge data
   - `balance.do`: Processes balance sheets (1992-2022), creates standardized variables
   - `ceo-panel.do`: Processes CEO registry, constructs firm-person-year structure
   - `unfiltered.do`: Merges datasets, applies industry classifications, creates variables
   - `analysis-sample.do`: Applies sample restrictions to create final analytical dataset
   - `placebo.do`: Generates placebo CEO transitions with same probability as actual changes but excluding actual transition periods
   - `edgelist.do`: Extracts firm-manager edgelist (frame_id_numeric, person_id) to CSV

3. **Utilities** (`code/util/`): Helper scripts called by main processing
   - `industry.do`: TEAOR08 industry sector classifications
   - `variables.do`: Derived variables (logs, tenure, age, firm characteristics)
   - `filter.do`: Final sample restrictions

4. **Exhibits** (`code/exhibit/`): Table generation for paper  
   - `table1.do`: Creates Table 1 - Sample Distribution Over Time with temporal distribution by year
   - `table2.do`: Creates Table 2 - CEO Patterns and Spell Length Analysis (two panels)
   - `table3.do`: Creates Table 3 - Revenue Function Estimation Results
   - `table4.do`: Creates Table 4 - Variance Decomposition of Firm Performance (reads pre-computed components from manager_value.do)
   - `tableA1.do`: Creates Table A1 - Industry-Level Summary Statistics using TEAOR08 classification (appendix)

5. **Analysis** (`code/estimate/`): Econometric estimation
   - `surplus.do`: Estimates revenue function and residualizes surplus for skill identification
   - `revenue_function.do`: Estimates revenue function models and saves results for table creation  
   - `event_study.do`: Implements placebo-controlled event study design comparing actual vs placebo CEO transitions
   - `manager_value.do`: Estimates manager fixed effects, generates distribution plots, and computes variance decomposition components (saved to temp/within_firm.dta and temp/cross_section.dta)

6. **Exhibits** (`code/exhibit/`): Table and figure generation
   - `table1.do`: Descriptive statistics over time
   - `table2.do`: CEO patterns and spell length analysis (two panels)
   - `table3.do`: Revenue function estimation results
   - `table4.do`: Variance decomposition table (uses pre-computed components from manager_value.do)
   - `tableA1.do`: Industry-level summary statistics (appendix)
   - `figure1.do`: Event study two-panel figure creation

7. **Output** (`temp/`, `output/`): Intermediate data and final results
   - `temp/`: Processed Stata datasets, edgelist CSV, connected component results, event study frames, variance decomposition components
   - `output/table/`: LaTeX tables for paper (including table4a.tex for variance decomposition)
   - `output/figure/`: Publication-ready figures  
   - `output/paper.pdf`: Final compiled document

### Network Analysis Component
`code/create/connected_component.jl` implements graph algorithms for CEO network analysis:
- Reads firm-manager edgelist from `temp/edgelist.csv`
- Projects bipartite graph to manager-manager network via shared firms
- Finds largest connected component of managers
- Outputs manager person_ids in largest component to `temp/large_component_managers.csv`
- Uses modular functions with configurable column names for flexibility

## Key Methodological Contributions

### Placebo-Controlled Event Study Design
The project implements a novel placebo-controlled approach to identify true CEO effects:
- **Placebo transitions**: Randomly assigned fake CEO changes that exclude actual transition periods
- **Sample selection**: Excludes firms that never reach 5 employees to focus on economically meaningful businesses
- **Event window**: Examines -4 to +3 years around CEO transition with year -1 as baseline
- **Key finding**: 75% of apparent CEO effects are spurious (noise rather than true skill differences)
- **True causal effect**: 5.5% (only 25% of the raw 22.5% correlation)
- **Variance analysis**: Tracks both mean and variance of revenue changes, where increased post-transition variance indicates heterogeneous firm responses to new management
- **Validation**: Aligns with theoretical predictions from Gaure (2014), Bonhomme et al. (2023), and Andrews et al. (2008)

### Addressing Measurement Challenges
The methodology addresses fundamental issues in the manager effects literature:
- **Limited mobility bias**: Placebo design separates mechanical bias from true effects
- **Correlation bias**: Two-way fixed effects carefully implemented with connected component restriction
- **Scale advantage**: 1M firms and 1M managers over 30 years provides unprecedented statistical power
- **External validation**: Quasi-experimental studies (Bennedsen et al. 2020, Chandra et al. 2016) find similar magnitudes

## Key Dependencies

- **Stata 18.0**: All data processing and econometric analysis
- **Julia**: Graph algorithms (packages: CSV, DataFrames, Graphs, SparseArrays)
- **LaTeX**: Document compilation with standard packages (booktabs, graphicx, natbib, hyperref, apacite)
- **Make**: Build automation with dependency tracking

## File Structure Notes

- All scripts must be run from project root directory
- Relative paths are used throughout
- Intermediate data saved to `temp/`
- Log files generated for all Stata operations
- Final analytical sample: Firm-year observations excluding firms never reaching 5 employees
- Event study sample: Firms with exactly one CEO change (after 5-employee filter)
- Event study baseline: Year -1 (one year before CEO transition)
- Event study window: -4 to +3 years around transition
- Placebo-controlled treatment effect: 5.5% (25% of raw correlation)

## Stata Coding Style

Beyond the CEU MicroData Stata Style Guide, this project follows additional conventions:

### Script Structure
- Start with `*!` version and description comments
- Use `clear all` for setup (not `set more off` or `cap log close`)
- Use section dividers with `* =============================================================================`
- End sections with descriptive `display` statements

### Variable Creation
- Use `generate byte` for binary variables when memory efficient
- Use `generate str` for string variables with explicit type
- Prefer `egen` functions with `by()` option over `bysort` + `generate`
- Use descriptive temporary variable names (e.g., `fmtag`, `max_n_managers`)

### Data Manipulation Patterns
- Use `keep if` early to reduce dataset size
- Use `drop` immediately after variables are no longer needed
- Use `preserve`/`restore` for temporary data operations
- Use `tempfile` and backtick notation for temporary datasets
- Use `collapse` with multiple statistics: `(mean) var1 (firstnm) var2`

### Advanced Techniques
- Use `egen tag()` for creating unique identifiers across groups
- Use `reshape wide` for pivoting data with string suffixes
- Use `merge ... using ..., keep(match) nogen` for clean merging
- Use `inrange()` function instead of `>= & <=` conditions
- Use `!missing()` instead of `~missing()` for clarity

### Comments and Documentation
- Use explanatory comments before complex operations
- Include verification steps with `count if` statements
- Add context for business logic (e.g., "switching years can be noisy")
- Use descriptive variable names that don't require comments

### Creating Exhibits and Tables
- Exhibit code lives in `code/exhibit/` directory
- Exhibits are named `table1.do`, `table2.do`, `table3.do`, `tableA1.do`, etc.
- Output files are named `output/table/table1.tex`, `table2_panelA.tex`, `table2_panelB.tex`, `table3.tex`, `table4a.tex`, `tableA1.tex`, etc.
- Use programmatic LaTeX generation with `file write` commands for custom tables
- Use `esttab` for regression tables with `booktabs` option for clean formatting
- Include comprehensive table notes using `\begin{tablenotes}[flushleft]` and `\footnotesize`
- For long tables, show selected rows (e.g., every 5th year + first/last + totals)
- Use 9999 as indicator for total/summary rows when appending aggregated data
- Format numbers with thousand separators using `%12.0fc`
- Create summary statistics at the end of scripts for log file documentation
- In Makefile: exhibit dependencies include both data files and connected component CSV files
- For esttab labels with underscores, use `filefilter` to clean LaTeX-incompatible characters

### LaTeX Table Formatting Preferences
- Use equal-width centered columns: `\begin{tabular}{*{6}{c}}` instead of `lccccc`
- Use `\multicolumn{2}{c}{Group header}` with `\cmidrule(lr){5-6}` for column groupings
- Use `\shortstack{Text\\line}` for multi-line column headers to save horizontal space
- Set minipage width to match table content (e.g., `\begin{minipage}{12cm}` for 6×2cm columns)
- Prefer descriptive but concise column names: "Sample firms" over "Filtered firms"
- Avoid table width wider than column content - table notes should not extend beyond table
- When calculating totals, use distinct counts not sums of yearly observations
- Structure complex data processing with multiple `preserve`/`restore` blocks and `tempfile` operations

## Data Confidentiality

This project uses proprietary data that cannot be shared. Data files in `input/` are not included in repository and must be obtained separately from HUN-REN KRTK or Opten Zrt.

## Build and Development Notes

- **Make Timeout**: 
  * make takes long to run, adjust the timeout. 5 minutes is expected
- **Intermediate Files**:
  * Files in `temp/` are marked as `.PRECIOUS` in Makefile to prevent automatic deletion
  * These files are computationally expensive to generate (especially .dta, .csv, .ster files)
  * No `make clean` target exists - manual cleanup if needed

### Git and File Management
- Add `.bak` files to `.gitignore` alongside other LaTeX auxiliary files
- When creating backup files, use `.bak` extension consistently
- Ensure auxiliary file patterns in `.gitignore` cover all LaTeX compilation outputs
