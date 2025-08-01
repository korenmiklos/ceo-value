STATA := stata -b do
LATEX := pdflatex
JULIA := time julia --project=. 
UTILS := $(wildcard code/util/*.do)

all: output/paper.pdf

%.pdf: %.tex output/table/revenue_function.tex output/table/revenue_sectors.tex output/table/manager_effects.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf output/figure/manager_skill_correlation.pdf output/figure/event_study.pdf output/references.bib
	cd $(dir $@) && $(LATEX) $(notdir $<) && bibtex $(notdir $(basename $<)) && $(LATEX) $(notdir $<) && $(LATEX) $(notdir $<)

temp/analysis-sample.dta: code/create/analysis-sample.do temp/balance.dta temp/ceo-panel.dta $(UTILS)
	$(STATA) $<

temp/balance.dta: code/create/balance.do input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
	$(STATA) $<

temp/ceo-panel.dta: code/create/ceo-panel.do input/ceo-panel/ceo-panel.dta
	$(STATA) $<

temp/edgelist.csv: code/create/edgelist.do temp/analysis-sample.dta
	$(STATA) $<

temp/placebo.dta: code/create/placebo.do temp/analysis-sample.dta
	$(STATA) $<

output/table/revenue_function.tex output/table/revenue_sectors.tex output/table/revenue_controls.tex: code/estimate/revenue_function.do code/estimate/exit.do temp/analysis-sample.dta temp/large_component_managers.csv code/create/network-sample.do
	$(STATA) $<

temp/large_component_managers.csv: code/create/connected_component.jl temp/edgelist.csv
	$(JULIA) $<

temp/surplus.dta: code/estimate/surplus.do temp/analysis-sample.dta
	$(STATA) $<

output/table/manager_effects.tex output/figure/manager_skill_within.pdf output/figure/manager_skill_connected.pdf temp/manager_value.dta: code/estimate/manager_value.do temp/surplus.dta temp/large_component_managers.csv code/create/network-sample.do
	mkdir -p output/figure
	$(STATA) $<

output/figure/manager_skill_correlation.pdf output/figure/event_study.pdf: code/estimate/event_study.do temp/manager_value.dta temp/analysis-sample.dta
	mkdir -p output/figure
	$(STATA) $<

output/test/test_paths.csv: code/test/test_network.jl temp/edgelist.csv temp/large_component_managers.csv
	mkdir -p output/test
	$(JULIA) $< 1000 10

output/extract/2022_values.dta output/extract/manager_changes_2015.dta output/extract/connected_managers.dta: code/create/extract.do temp/manager_value.dta temp/surplus.dta temp/analysis-sample.dta input/ceo-panel/ceo-panel.dta
	mkdir -p output/extract
	$(STATA) $<

install.log: code/util/install.do 
	$(STATA) $<