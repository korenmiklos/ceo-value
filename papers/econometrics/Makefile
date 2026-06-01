.PHONY: all montecarlo paper clean
.SECONDARY: $(foreach sample,$(REAL_SAMPLES),$(foreach outcome,$(OUTCOMES),$(foreach fe,$(FIXED_EFFECTS),data/$(sample)_$(outcome)-$(fe).csv))) \
	$(foreach outcome,$(OUTCOMES),$(foreach fe,$(FIXED_EFFECTS),data/atet_full_$(outcome)-$(fe).csv)) \
	$(EVENT_STUDIES_TABLE) $(EVENT_STUDIES_GRAPH)
STATA := stata-mp

SCENARIOS = baseline persistent excessvariance excessvariance_corr all trend longpanel
EVENT_STUDIES_TABLE = $(addprefix data/atet_,$(addsuffix _lnR-lnR.csv,$(SCENARIOS)))
EVENT_STUDIES_GRAPH = $(addprefix data/,$(addsuffix _lnR-lnR.csv,$(SCENARIOS)))
OUTCOMES :=  lnR exporter lnL lnK ROA lnYL
REAL_SAMPLES := full one2one twos
FIXED_EFFECTS := lnR ROA lnYL
DATALIB := ../../temp/analysis-sample.dta ../../temp/manager_value.dta
CODELIB := ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do

all: $(foreach sample,$(REAL_SAMPLES),$(foreach fe, $(FIXED_EFFECTS), figure/outcomes_$(sample)_$(fe).pdf)) \
	$(foreach fe, $(FIXED_EFFECTS), table/atets_full_$(fe).tex)\
	table/firm-descriptives.tex \
	table/firm-year-descriptive.tex \
	table/max-emp-by-ceo-switches.tex \
	table/ceo-counts.tex \
	table/atets.tex \
	figure/ceo-spell-distributions.pdf \
	figure/ceo-spell-distributions-weighted.pdf \
	figure/tenure-snapshots.pdf \
	figure/outcomes.pdf

montecarlo: figure/figuremc.pdf table/atets.tex

#################################################################################
####### Applications: Generate data for creating application exhibits ###########
#################################################################################
data/placebo_%.dta: ../../temp/placebo_%.dta
	mkdir -p $(dir $@)
	cp $< $@

define lnR_RULE
data/$(1)_%-lnR.csv: $$(CODELIB) $$(DATALIB) data/placebo_$(1).dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" $(1) $$* no lnR excessvariance
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call lnR_RULE,$(sample))))

define ROA_RULE
data/$(1)_%-ROA.csv: $$(CODELIB) $$(DATALIB) data/placebo_$(1).dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" $(1) $$* no ROA excessvariance
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call ROA_RULE,$(sample))))

define lnYL_RULE
data/$(1)_%-lnYL.csv: $$(CODELIB) $$(DATALIB) data/placebo_$(1).dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" $(1) $$* no lnYL excessvariance
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call lnYL_RULE,$(sample))))

data/atet_full_%-lnR.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do ../../lib/estimate/event_study_atet.do full $* no lnR excessvariance

data/atet_full_%-ROA.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do ../../lib/estimate/event_study_atet.do full $* no ROA excessvariance

data/atet_full_%-lnYL.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do ../../lib/estimate/event_study_atet.do full $* no lnYL excessvariance


#################################################################################
####### Monte Carlo :Generate event study data for monte carlo scenarios ########
#################################################################################
# Ultra-concise version
MC_SCENARIOS := baseline persistent all trend longpanel excessvariance excessvariance_corr

define GEN_MC
data/$(1)_lnR-lnR.csv: $$(CODELIB) data/placebo_$$(if $$(filter excessvariance%,$(1)),excessvariance,$(1)).dta
	mkdir -p data
	$$(STATA) -b do ../../lib/estimate/event_study.do $(1) lnR montecarlo lnR $$(if $$(findstring _corr,$(1)),excessvariance,)

data/atet_$(1)_lnR-lnR.csv: $$(CODELIB) data/placebo_$$(if $$(filter excessvariance%,$(1)),excessvariance,$(1)).dta
	mkdir -p data
	$$(STATA) -b do ../../lib/estimate/event_study_atet.do $(1) lnR montecarlo lnR $$(if $$(findstring _corr,$(1)),excessvariance,)
endef

$(foreach scenario,$(MC_SCENARIOS),$(eval $(call GEN_MC,$(scenario))))

data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
	$(STATA) -b do src/montecarlo/run.do $*


#################################################################################
############################ EXHIBTIS ###########################################
#################################################################################
define OUTCOMES_RULE
figure/outcomes_$(1)_%.pdf: src/exhibit/outcomes.do $$(CODELIB) $$(foreach outcome, $$(OUTCOMES), data/$(1)_$$(outcome)-%.csv)
	mkdir -p figure
	$(STATA) -b do $$< $(1) $$*
endef
$(foreach sample,$(REAL_SAMPLES),$(eval $(call OUTCOMES_RULE,$(sample))))

figure/outcomes.pdf: src/exhibit/final_outcomes.do src/exhibit/event_study.do data/full_lnR-lnR.csv data/full_ROA-lnR.csv data/full_lnK-ROA.csv data/full_lnL-lnYL.csv
	mkdir -p figure
	$(STATA) -b do $<

table/atets_full_%.tex: src/exhibit/application_atets.do $(CODELIB) $(foreach outcome, $(OUTCOMES), data/atet_full_$(outcome)-%.csv)
	mkdir -p table
	$(STATA) -b do $< full $*

table/atets.tex: src/exhibit/atets.do $(EVENT_STUDIES_TABLE) $(EVENT_STUDIES_GRAPH) $(CODELIB)
	mkdir -p table
	$(STATA) -b do src/exhibit/atets.do

figure/figuremc.pdf: src/figuremc.do src/exhibit/event_study2.do src/exhibit/event_study3.do $(EVENT_STUDIES_GRAPH)
	mkdir -p figure
	$(STATA) -b do src/figuremc.do

table/%.tex: src/exhibit/%.do $(DATALIB) $(CODELIB)
	$(STATA) -b do $<

figure/ceo-%.pdf: src/exhibit/%.do $(DATALIB)
	$(STATA) -b do $<

figure/ceo-%-weighted.pdf: src/exhibit/%.do $(DATALIB)
	$(STATA) -b do $<

figure/%.pdf: src/exhibit/%.do $(DATALIB)
	$(STATA) -b do $<

paper.pdf: paper.tex table/atets.tex figure/application.pdf ../application/table/table1_panelAB.tex ../application/table/table2.tex ../application/table/tableA1.tex ../application/table/tableA3.tex ../application/table/tableA4.tex ../application/figure/figure1.pdf ../application/figure/figure2.pdf ../application/figure/figure3.pdf figure/figuremc.pdf ../../lib/references.bib
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex

paper: paper.pdf
