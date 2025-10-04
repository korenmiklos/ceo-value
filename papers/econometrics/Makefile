.PHONY: all montecarlo paper clean

SCENARIOS = baseline longpanel persistent unbalanced excessvariance all
PLACEBO_DATA = $(addprefix data/placebo_,$(addsuffix .dta,$(SCENARIOS)))

all: paper

montecarlo: $(PLACEBO_DATA)

$(PLACEBO_DATA): src/montecarlo.do src/montecarlo/params.do src/montecarlo/setup.do $(wildcard src/montecarlo/*.do)
	stata -b do src/montecarlo.do

paper.pdf: paper.tex ../application/table/table1_panelAB.tex ../application/table/table2.tex ../application/table/tableA1.tex ../application/table/tableA3.tex ../application/table/tableA4.tex ../application/figure/figure1.pdf ../application/figure/figure2.pdf ../application/figure/figure3.pdf ../../lib/references.bib
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex

paper: paper.pdf

clean:
	rm -f data/placebo_*.dta
	rm -f paper.pdf paper.aux paper.log paper.out paper.bbl paper.blg
