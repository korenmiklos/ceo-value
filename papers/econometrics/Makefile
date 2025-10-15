.PHONY: all montecarlo paper clean

SCENARIOS = baseline longpanel persistent unbalanced excessvariance all
EVENT_STUDIES = $(addprefix data/,$(addsuffix _lnR.csv,$(SCENARIOS)))
OUTCOMES := lnR

all: paper

montecarlo: $(EVENT_STUDIES)

data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
	stata -b do src/montecarlo/run.do $*

# copy relevant files for application
data/placebo_full.dta: ../../temp/placebo_full.dta
	mkdir -p $(dir $@)
	cp $< $@

# same with real data
data/full_%.csv: ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no lnR

data/full_exporter.csv: ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full exporter no lnR

# Generate event study data for monte carlo scenarios
data/%_lnR.csv: ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do data/placebo_%.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" $* lnR montecarlo lnR

table/atets.tex: src/exhibit/atets.do $(EVENT_STUDIES)
	mkdir -p table
	stata -b do "src/exhibit/atets.do"

figure/figuremc.pdf: src/figuremc.do src/exhibit/event_study.do $(EVENT_STUDIES)
	mkdir -p figure
	stata -b do "src/figuremc.do"

figure/application.pdf: src/application.do src/exhibit/age.do src/exhibit/event_study.do src/exhibit/event_study3.do data/full_lnR.csv data/full_exporter.csv ../../temp/surplus.dta ../../temp/analysis-sample.dta ../../temp/manager_value.dta
	mkdir -p figure
	stata -b do "src/application.do"

paper.pdf: paper.tex table/atets.tex figure/application.pdf ../application/table/table1_panelAB.tex ../application/table/table2.tex ../application/table/tableA1.tex ../application/table/tableA3.tex ../application/table/tableA4.tex ../application/figure/figure1.pdf ../application/figure/figure2.pdf ../application/figure/figure3.pdf figure/figuremc.pdf ../../lib/references.bib
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex

paper: paper.pdf

clean:
	rm -f data/placebo_*.dta data/*_TFP.csv
	rm -f table/atets.tex
	rm -f figure/figuremc.pdf figure/application.pdf
	rm -f paper.pdf paper.aux paper.log paper.out paper.bbl paper.blg
