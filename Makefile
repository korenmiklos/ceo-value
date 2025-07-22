all: output/paper.pdf

%.pdf: %.tex
	cd $(dir $@) && pdflatex $(notdir $<) && $(notdir $<)

