STATA := stata -b do
LATEX := pdflatex

all: output/paper.pdf

%.pdf: %.tex
	cd $(dir $@) && $(LATEX) $(notdir $<) && $(LATEX) $(notdir $<)

temp/analysis-sample.dta: code/create/analysis-sample.do temp/balance.dta temp/ceo-panel.dta
	$(STATA) $<

temp/balance.dta: code/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

temp/ceo-panel.dta: code/create/ceo-panel.do input/ceo-panel/ceo-panel.dta
	$(STATA) $<

