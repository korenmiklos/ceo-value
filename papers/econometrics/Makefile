.PHONY: all montecarlo paper clean

SCENARIOS = baseline longpanel persistent unbalanced excessvariance all
PLACEBO_DATA = $(addprefix data/placebo_,$(addsuffix .dta,$(SCENARIOS)))
OUTCOMES := TFP

all: paper

montecarlo: $(PLACEBO_DATA)

data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
	stata -b do src/montecarlo/run.do $*

# Generate event study data for monte carlo scenarios
data/%_TFP.csv: ../../lib/estimate/event_study.do ../../lib/estimate/setup_event_study.do data/placebo_%.dta
	mkdir -p data
	stata -b do "../../lib/estimate/event_study.do" $* TFP montecarlo

figure/figuremc.pdf: src/figuremc.do data/baseline_TFP.csv
	mkdir -p figure
	stata -b do "src/figuremc.do"

paper.pdf: paper.tex ../application/table/table1_panelAB.tex ../application/table/table2.tex ../application/table/tableA1.tex ../application/table/tableA3.tex ../application/table/tableA4.tex ../application/figure/figure1.pdf ../application/figure/figure2.pdf ../application/figure/figure3.pdf figure/figuremc.pdf ../../lib/references.bib
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex

paper: paper.pdf

clean:
	rm -f data/placebo_*.dta data/*_TFP.csv
	rm -f figure/figuremc.pdf
	rm -f paper.pdf paper.aux paper.log paper.out paper.bbl paper.blg
