*! version 1.0.0 2025-08-31
* =============================================================================
* Exhibit Reorganization - Issue #10
* =============================================================================
* Reorganize exhibits: keep outcome-rotation table and event-study figures in main;
* move composition-heavy tables to appendix; update captions

clear all

* This script creates commands to reorganize the paper structure
* Run this after generating all the new analysis files

display "=== EXHIBIT REORGANIZATION PLAN ==="
display ""

display "MAIN TEXT EXHIBITS (keep):"
display "- Table 1: Sample characteristics"
display "- Table 2: Outcome rotation analysis (NEW)"
display "- Table 3: Revenue function estimation (keep current Table 3)"
display "- Figure 1: Event study results (keep)"
display "- Table 4: Coverage rationale (NEW)"
display ""

display "APPENDIX EXHIBITS (move from main):"
display "- Table A1: Industry statistics (current Table A1)"
display "- Table A2: CEO patterns and spell lengths (current Table 2)"
display "- Table A3: Manager skill by sector/ownership (current Table 4)"
display "- Table A4: Missingness patterns (NEW)"
display ""

display "FILES TO CREATE/MODIFY:"
display "1. Update output/paper.tex with new structure"
display "2. Update Makefile with new dependencies"
display "3. Create new exhibit scripts"

* Save reorganization plan
file open reorg using "temp/reorganization_plan.txt", write replace text

file write reorg "EXHIBIT REORGANIZATION PLAN" _n
file write reorg "==============================" _n _n

file write reorg "MAIN TEXT:" _n
file write reorg "Table 1: Sample characteristics (unchanged)" _n
file write reorg "Table 2: Outcome rotation analysis (NEW - from outcome_rotation.do)" _n
file write reorg "Table 3: Revenue function results (unchanged)" _n  
file write reorg "Figure 1: Event study (unchanged)" _n
file write reorg "Table 4: Coverage rationale (NEW - from missingness_analysis.do)" _n _n

file write reorg "APPENDIX:" _n
file write reorg "Table A1: Industry statistics (move from main)" _n
file write reorg "Table A2: CEO patterns/spells (move current Table 2)" _n
file write reorg "Table A3: Manager skill variation (move current Table 4)" _n  
file write reorg "Table A4: Missingness patterns (NEW - from missingness_analysis.do)" _n
file write reorg "Table A5: Sample sizes by outcome (NEW - from outcome_rotation.do)" _n

file close reorg

display "Reorganization plan saved to temp/reorganization_plan.txt"
