.PHONY: all montecarlo paper clean

SCENARIOS = baseline longpanel persistent unbalanced excessvariance all
EVENT_STUDIES = $(addprefix data/,$(addsuffix _lnR.csv,$(SCENARIOS)))
OUTCOMES :=  lnROA lnR exporter lnL lnM lnK has_intangible lnKL lnRL lnMR EBITDA_share
FIXED_EFFECTS := lnR lnROA investment
DATALIB := ../../temp/analysis-sample.dta ../../temp/manager_value.dta
CODELIB := ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do

all: $(foreach FE,$(FIXED_EFFECTS),figure/outcomes_$(FE).pdf) 

montecarlo: $(EVENT_STUDIES)

figure/outcomes_%.pdf: src/outcomes.do $(foreach outcome,$(OUTCOMES),data/full_$(outcome)-%.csv)
	mkdir -p figure
	stata -b do $<

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

data/full_%-lnROA.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no lnROA

data/full_%-lnL.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no lnL

data/full_%-lnRL.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no lnRL

data/full_%-investment.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" full $* no investment

# Generate event study data for monte carlo scenarios
data/%_lnR.csv: $(CODELIB) data/placebo_%.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" $* lnR montecarlo lnR

table/atets.tex: src/exhibit/atets.do $(EVENT_STUDIES)
	mkdir -p table
	stata -b do "src/exhibit/atets.do"

figure/figuremc.pdf: src/figuremc.do src/exhibit/event_study2.do src/exhibit/event_study3.do $(EVENT_STUDIES)
	mkdir -p figure
	stata -b do "src/figuremc.do"

paper.pdf: paper.tex table/atets.tex figure/application.pdf ../application/table/table1_panelAB.tex ../application/table/table2.tex ../application/table/tableA1.tex ../application/table/tableA3.tex ../application/table/tableA4.tex ../application/figure/figure1.pdf ../application/figure/figure2.pdf ../application/figure/figure3.pdf figure/figuremc.pdf ../../lib/references.bib
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex

paper: paper.pdf
