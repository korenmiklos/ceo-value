.PHONY: all montecarlo clean

SCENARIOS = baseline longpanel persistent unbalanced excessvariance all
PLACEBO_DATA = $(addprefix data/placebo_,$(addsuffix .dta,$(SCENARIOS)))

all: montecarlo

montecarlo: $(PLACEBO_DATA)

$(PLACEBO_DATA): src/montecarlo.do src/montecarlo/params.do src/montecarlo/setup.do $(wildcard src/montecarlo/*.do)
	cd ../.. && stata -b do papers/econometrics/src/montecarlo.do

clean:
	rm -f data/placebo_*.dta
