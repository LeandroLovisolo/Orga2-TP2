.PHONY: all

all: informe.pdf

informe.pdf: *.tex
	latexmk -pdf -pdflatex="pdflatex -interactive=nonstopmode -halt-on-error" informe.tex

clean:
	latexmk -CA