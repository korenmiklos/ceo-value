.PHONY: all montecarlo clean
STATA := stata-mp

SCENARIOS = baseline persistent excessvariance excessvariance_corr all trend longpanel
OUTCOMES :=  lnR lnL lnK ROA lnRL
SAMPLES := full one2one twos fnd2non non2non gender nogender gap nogap
FIXED_EFFECTS := lnR ROA lnRL
VARIATIONS := full size1 size2 size3 size4 pre2000 post2000
DATALIB := ../../temp/analysis-sample.dta ../../temp/manager_value.dta
CODELIB := ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do ../../lib/estimate/xt2var.do

all: $(foreach sample,$(SAMPLES), figure/outcomes_$(sample).pdf) \
	table/r2s_full.tex\
	table/firm-descriptives.tex \
	table/firm-year-descriptives.tex \
	table/switch-descriptives.tex \
	table/industry-descriptives.tex \
	table/atets.tex \
	$(foreach variation,$(VARIATIONS),table/$(variation)_debiased_r2s.tex) \
	figure/ceo-spell-distributions.pdf \
	figure/ceo-spell-distributions-weighted.pdf \
	figure/tenure-snapshots.pdf \
	figure/outcomes.pdf


montecarlo: figure/figuremc.pdf table/atets.tex

#################################################################################
####### Applications: Generate data for creating application exhibits ###########
#################################################################################
define placebo_rule
data/$(1)_placebo_%.dta: ../../temp/$(1)_placebo_%.dta
	mkdir -p $$(dir $$@)
	cp $$< $$@
endef
$(foreach variation, $(VARIATIONS), $(eval $(call placebo_rule,$(variation))))

define effects_RULE
data/$(1)_$(2)_$(3)-$(3).csv: $$(CODELIB) $$(DATALIB) data/$(1)_placebo_$(2).dta
	mkdir -p data
	$$(STATA) -b do "../../lib/estimate/event_study.do" $(1) $(2) $(3) no $(3) excessvariance
endef
$(foreach variation, $(VARIATIONS),$(foreach sample,$(SAMPLES),$(foreach outcome, $(OUTCOMES), $(eval $(call effects_RULE,$(variation),$(sample),$(outcome))))))

data/full_full_ROA-lnR.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" full full ROA no lnR excessvariance

data/full_full_lnK-ROA.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" full full lnK no ROA excessvariance

data/full_full_lnL-lnRL.csv: $(CODELIB) $(DATALIB) data/placebo_full.dta
	mkdir -p data
	$(STATA) -b do "../../lib/estimate/event_study.do" full full lnL no lnRL excessvariance

define atets_RULE
data/atet_$(1)_$(2)_$(3)-$(3).csv: $$(CODELIB) $$(DATALIB) data/$(1)_placebo_$(2).dta
	mkdir -p data
	$$(STATA) -b do ../../lib/estimate/event_study_atet.do $(1) $(2) $(3) no $(3) excessvariance
endef
$(foreach variation,$(VARIATIONS),$(foreach sample,$(SAMPLES),$(foreach outcome,$(OUTCOMES),$(eval $(call atets_RULE,$(variation),$(sample),$(outcome))))))

#################################################################################
####### Monte Carlo :Generate event study data for monte carlo scenarios ########
#################################################################################
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
figure/outcomes_%.pdf: src/exhibit/outcomes.do \
	$(CODELIB) \
	$(foreach outcome, $(OUTCOMES), data/%_$(outcome)-$(outcome).csv)
	mkdir -p figure
	$(STATA) -b do $< $*

figure/outcomes.pdf: src/exhibit/final_outcomes.do \
		src/exhibit/event_study.do \
		data/full_full_lnR-lnR.csv \
		data/full_full_ROA-lnR.csv \
		data/full_full_lnK-ROA.csv \
		data/full_full_lnL-lnRL.csv
	mkdir -p figure
	$(STATA) -b do $<

table/r2s_full.tex: src/exhibit/application_r2s.do $(CODELIB) \
		data/atet_full_full_lnR-lnR.csv \
		data/atet_full_full_lnRL-lnRL.csv \
		data/atet_full_full_ROA-ROA.csv \
		data/atet_full_full_lnL-lnL.csv \
		data/atet_full_full_lnK-lnK.csv
	mkdir -p table
	$(STATA) -b do $< full

define debiased_rule
table/$(1)_debiased_r2s.tex: src/exhibit/debiased_r2s.do $$(CODELIB) \
	$$(foreach sample, $$(SAMPLES),$$(foreach outcome, $$(OUTCOMES), data/atet_$(1)_$$(sample)_$$(outcome)-$$(outcome).csv))
	mkdir -p table
	$$(STATA) -b do $$< $(1)
endef
$(foreach variation, $(VARIATIONS), $(eval $(call debiased_rule,$(variation))))


table/atets.tex: src/exhibit/atets.do $(CODELIB)
	mkdir -p table
	$(STATA) -b do src/exhibit/atets.do

figure/figuremc.pdf: src/figuremc.do  \
	src/exhibit/event_study2.do \
	src/exhibit/event_study3.do \
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

