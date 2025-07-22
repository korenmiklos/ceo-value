STATA := stata -b do
LATEX := pdflatex
UTILS := $(wildcard code/util/*.do)

all: output/paper.pdf

%.pdf: %.tex output/table/full_sample.tex output/table/EBITDA_sectors.tex
	cd $(dir $@) && $(LATEX) $(notdir $<) && $(LATEX) $(notdir $<)

output/table/full_sample.tex output/table/EBITDA_sectors.tex: code/estimate/surplus.do temp/analysis-sample.dta
	$(STATA) $<

temp/analysis-sample.dta: code/create/analysis-sample.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
	$(STATA) $<

temp/balance.dta: code/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

temp/ceo-panel.dta: code/create/ceo-panel.do input/ceo-panel/ceo-panel.dta
	$(STATA) $<

