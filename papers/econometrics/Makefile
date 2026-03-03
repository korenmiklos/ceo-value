.PHONY: all montecarlo paper clean

SCENARIOS = baseline longpanel persistent_baseline persistent unbalanced excessvariance_baseline excessvariance all all_persistent all_excess all_both
EVENT_STUDIES = $(addprefix data/,$(addsuffix _lnR-lnR.csv,$(SCENARIOS)))
OUTCOMES :=  ROA lnR exporter lnL lnK lnWL
REAL_SAMPLES := full one2one twos
FIXED_EFFECTS := lnR ROA
DATALIB := ../../temp/analysis-sample.dta ../../temp/manager_value.dta
CODELIB := ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do

all: $(foreach sample,$(REAL_SAMPLES),$(foreach fe, $(FIXED_EFFECTS), figure/outcomes_$(sample)_$(fe).pdf)) \
	table/firm-descriptives.tex \
	table/firm-year-descriptives.tex \
	table/max-emp-by-ceo-switches.tex \
	table/ceo-counts.tex \
	table/atets.tex \
	figure/ceo-spell-distributions.pdf \
	figure/ceo-spell-distributions-weighted.pdf \
	figure/tenure-snapshots.pdf

montecarlo: $(EVENT_STUDIES)

define OUTCOMES_RULE
figure/outcomes_$(1)_%.pdf: src/outcomes.do $$(foreach outcome,$$(OUTCOMES),data/$(1)_$$(outcome)-%.csv)
	mkdir -p figure
	stata -b do $$< $(1) $$*
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call OUTCOMES_RULE,$(sample))))

application: $(foreach sample,$(REAL_SAMPLES),$(foreach outcome,$(OUTCOMES),data/$(sample)_$(outcome)-lnR.csv)) \
	$(foreach sample,$(REAL_SAMPLES),$(foreach outcome,$(OUTCOMES),data/$(sample)_$(outcome)-ROA.csv))

# copy relevant files for application
data/placebo_%.dta: ../../temp/placebo_%.dta
	mkdir -p $(dir $@)
	cp $< $@

data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
	stata -b do src/montecarlo/run.do $*

# Generate event study data for real data samples
define lnR_RULE
data/$(1)_%-lnR.csv: $$(CODELIB) $$(DATALIB) data/placebo_$(1).dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" $(1) $$* no lnR
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call lnR_RULE,$(sample))))

define ROA_RULE
data/$(1)_%-ROA.csv: $$(CODELIB) $$(DATALIB) data/placebo_$(1).dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" $(1) $$* no ROA
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call ROA_RULE,$(sample))))


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
