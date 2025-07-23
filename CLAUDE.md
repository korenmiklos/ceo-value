# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an academic research project analyzing the impact of CEOs on privately held Hungarian businesses from 1992-2022. The project processes proprietary administrative data using Stata, Julia, and LaTeX to generate tables and figures for an economics paper.

## Core Commands

### Build the entire project
```bash
make all
```
This runs all Stata scripts in dependency order and compiles the final PDF.

### Individual components
```bash
# Process balance sheet data
stata -b do code/create/balance.do

# Process CEO panel data  
stata -b do code/create/ceo-panel.do

# Create analysis sample
stata -b do code/create/analysis-sample.do

# Run econometric analysis
stata -b do code/estimate/surplus.do

# Julia graph analysis
julia --project=. code/create/connected_component.jl

# Compile LaTeX document
cd output && pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
```

### Manual execution (if Make unavailable)
```bash
stata -b do code/create/balance.do
stata -b do code/create/ceo-panel.do  
stata -b do code/create/analysis-sample.do
cd output && pdflatex paper.tex && pdflatex paper.tex
```

## Architecture

### Data Pipeline
1. **Raw Data** (`input/`): Proprietary Hungarian administrative datasets
   - `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta`: Balance sheet data
   - `input/ceo-panel/ceo-panel.dta`: CEO registry data

2. **Processing** (`code/create/`): Stata scripts that clean and merge data
   - `balance.do`: Processes balance sheets (1992-2022), creates standardized variables
   - `ceo-panel.do`: Processes CEO registry, constructs firm-person-year structure  
   - `analysis-sample.do`: Merges datasets, applies industry classifications and sample restrictions

3. **Utilities** (`code/util/`): Helper scripts called by main processing
   - `industry.do`: TEAOR08 industry sector classifications
   - `variables.do`: Derived variables (logs, tenure, age, firm characteristics)
   - `filter.do`: Final sample restrictions

4. **Analysis** (`code/estimate/`): Econometric estimation
   - `surplus.do`: Generates regression tables for paper

5. **Output** (`temp/`, `output/`): Intermediate data and final results
   - `temp/`: Processed Stata datasets
   - `output/table/`: LaTeX tables for paper
   - `output/paper.pdf`: Final compiled document

### Julia Component
`code/create/connected_component.jl` implements graph algorithms for network analysis of CEO connections using:
- Bipartite graph projection
- Connected component analysis
- Sparse matrix operations

## Key Dependencies

- **Stata 18.0**: All data processing and econometric analysis
- **Julia**: Graph algorithms (packages: CSV, DataFrames, Graphs, SparseArrays)
- **LaTeX**: Document compilation with standard packages (booktabs, graphicx, natbib, hyperref)
- **Make**: Build automation

## File Structure Notes

- All scripts must be run from project root directory
- Relative paths are used throughout
- Intermediate data saved to `temp/`
- Log files generated for all Stata operations
- Final analytical sample: 8,872,039 firm-year observations

## Data Confidentiality

This project uses proprietary data that cannot be shared. Data files in `input/` are not included in repository and must be obtained separately from HUN-REN KRTK or Opten Zrt.