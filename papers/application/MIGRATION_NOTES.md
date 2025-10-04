# Makefile Migration to Monorepo Structure

## Changes Made

### 1. Makefile Location
- **Old**: `/ceo-value/Makefile`  
- **New**: `/ceo-value/papers/application/Makefile`

### 2. Key Path Updates

#### Code References
- `code/` → `../../lib/` (shared library code)
- `code/exhibit/` → `papers/application/src/exhibit/` (paper-specific exhibits)
- `code/util/` → `../../lib/util/`
- `code/create/` → `../../lib/create/`
- `code/estimate/` → `../../lib/estimate/`

#### Data Paths  
- `temp/` → `../../temp/` (shared temp directory)
- `input/` → `../../input/` (shared input directory)
- `output/` → `../../output/` (for shared outputs)

#### Paper-Specific Outputs
- `output/table/` → `papers/application/table/`
- `output/figure/` → `papers/application/figure/`

### 3. Exhibit Script Updates

All scripts in `papers/application/src/exhibit/` were updated:

- **table1.do**: Output path updated to `papers/application/table/table1_panelAB.tex`
- **table2.do**: Output paths updated to `papers/application/table/table2_panel[A|B].tex`
- **table3.do**: 
  - Changed `code/create/network-sample.do` → `lib/create/network-sample.do`
  - Output path → `papers/application/table/table3.tex`
- **tableA0.do**: Output path → `papers/application/table/tableA0.tex`
- **tableA1.do**: Output path → `papers/application/table/tableA1.tex`
- **figure1.do**: Output path → `papers/application/figure/figure1.pdf`
- **figure2.do**: 
  - `code/exhibit/event_study.do` → `papers/application/src/exhibit/event_study.do`
  - Output path → `papers/application/figure/figure2.pdf`
- **figure3.do**: 
  - `code/exhibit/event_study.do` → `papers/application/src/exhibit/event_study.do`
  - Output path → `papers/application/figure/figure3.pdf`
- **figuremc.do**: Similar updates to figure2/3

### 4. Working Directory Strategy

All Stata/Julia commands run from project root using `cd ../..`:
```make
../../temp/balance.dta: ../../lib/create/balance.do
	cd ../.. && $(STATA) lib/create/balance.do
```

This ensures:
- Scripts can use relative paths like `temp/balance.dta` 
- Shared library code remains accessible
- Paper-specific outputs go to correct locations

### 5. Julia Project Path

Updated Julia invocation:
```make
JULIA := julia --project=../..
```

### 6. Directory Cleanup

- Flattened `papers/application/table/table/` → `papers/application/table/`
- Flattened `papers/application/figure/figure/` → `papers/application/figure/`

## Running the Build

From the paper directory:
```bash
cd papers/application
make all          # Full build
make data         # Data wrangling only
make analysis     # Analysis only  
make paper.pdf    # Compile paper
```

## Testing

Dry run test passed:
```bash
cd papers/application && make -n paper.pdf
```

All paths resolved correctly with proper execution from root directory.
