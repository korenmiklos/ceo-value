STATA := stata -b do
LATEX := pdflatex
JULIA := time julia --project=. 
UTILS := $(wildcard code/util/*.do)

all: output/paper.pdf

%.pdf: %.tex output/table/revenue_function.tex output/table/revenue_sectors.tex output/table/manager_effects.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/references.bib
	cd $(dir $@) && $(LATEX) $(notdir $<) && bibtex $(notdir $(basename $<)) && $(LATEX) $(notdir $<) && $(LATEX) $(notdir $<)

temp/analysis-sample.dta: code/create/analysis-sample.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
	$(STATA) $<

temp/balance.dta: code/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

temp/ceo-panel.dta: code/create/ceo-panel.do input/ceo-panel/ceo-panel.dta
	$(STATA) $<

temp/edgelist.csv: code/create/edgelist.do temp/analysis-sample.dta
	$(STATA) $<

output/table/revenue_function.tex output/table/revenue_sectors.tex: code/estimate/revenue_function.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	$(STATA) $<

temp/large_component_managers.csv: code/create/connected_component.jl temp/edgelist.csv
	$(JULIA) $<

temp/surplus.dta: code/estimate/surplus.do temp/analysis-sample.dta
	$(STATA) $<

output/table/manager_effects.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf: code/estimate/manager_value.do temp/surplus.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p output/figure
	$(STATA) $<
