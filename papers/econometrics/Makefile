.PHONY: all montecarlo paper clean

SCENARIOS = baseline longpanel persistent_baseline persistent unbalanced excessvariance_baseline excessvariance all all_persistent all_excess all_both 
EVENT_STUDIES = $(addprefix data/,$(addsuffix _lnR-lnR.csv,$(SCENARIOS))) 
OUTCOMES :=  ROA lnR exporter lnL lnK lnWL
FIXED_EFFECTS := lnR ROA 
DATALIB := ../../temp/analysis-sample.dta ../../temp/manager_value.dta
CODELIB := ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do

all: $(foreach FE,$(FIXED_EFFECTS),figure/outcomes_$(FE).pdf) \
	table/firm-descriptives.tex \
	table/firm-year-descriptives.tex \
	table/max-emp-by-ceo-switches.tex \
	table/managers-in-lifetime.tex \
	figure/ceo-spell-distributions.pdf \
	figure/ceo-spell-distributions-weighted.pdf \
	figure/ridgeline-ROA.pdf \
	figure/tenure-snapshots.pdf

montecarlo: $(EVENT_STUDIES)

figure/outcomes_%.pdf: src/outcomes.do $(foreach outcome,$(OUTCOMES),data/full_$(outcome)-%.csv)
	mkdir -p figure
	stata -b do $< $*

application: $(foreach FE,$(FIXED_EFFECTS),$(foreach outcome,$(OUTCOMES),data/full_$(outcome)-$(FE).csv))

# copy relevant files for application
data/placebo_%.dta: ../../temp/placebo_%.dta
	mkdir -p $(dir $@)
	cp $< $@

data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
	stata -b do src/montecarlo/run.do $*

# same with real data
data/full_%-lnR.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no lnR

data/full_%-ROA.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no ROA


# Generate event study data for monte carlo scenarios
data/%_lnR-lnR.csv: $(CODELIB) data/placebo_%.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" $* lnR montecarlo lnR

table/atets.tex: src/exhibit/atets.do $(EVENT_STUDIES)
	mkdir -p table
	stata -b do "src/exhibit/atets.do"

figure/figuremc.pdf: src/figuremc.do src/exhibit/event_study2.do src/exhibit/event_study3.do $(EVENT_STUDIES)
	mkdir -p figure
	stata -b do "src/figuremc.do"

figure/figuremc-rho.pdf: src/figuremc-rho.do src/exhibit/event_study2.do src/exhibit/event_study3.do $(EVENT_STUDIES)
	mkdir -p figure
	stata -b do "src/figuremc-rho.do"

figure/figuremc-epsilon.pdf: src/figuremc-epsilon.do src/exhibit/event_study2.do src/exhibit/event_study3.do $(EVENT_STUDIES)
	mkdir -p figure
	stata -b do "src/figuremc-epsilon.do"

figure/figuremc-all.pdf: src/figuremc-all.do src/exhibit/event_study2.do src/exhibit/event_study3.do $(EVENT_STUDIES)
	mkdir -p figure 
	stata -b do "src/figuremc-all.do"

table/%.tex: src/%.do $(DATALIB)
	stata -b do $<

figure/ridgeline-ROA.pdf: src/roa-distributions.do $(DATALIB)
	stata -b do $<

figure/ceo-%.pdf: src/%.do $(DATALIB)
	stata -b do $<

figure/%.pdf: src/%.do $(DATALIB)
	stata -b do $<

paper.pdf: paper.tex table/atets.tex figure/application.pdf ../application/table/table1_panelAB.tex ../application/table/table2.tex ../application/table/tableA1.tex ../application/table/tableA3.tex ../application/table/tableA4.tex ../application/figure/figure1.pdf ../application/figure/figure2.pdf ../application/figure/figure3.pdf figure/figuremc.pdf ../../lib/references.bib
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex

paper: paper.pdf
