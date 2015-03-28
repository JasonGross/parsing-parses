CORE_MODULES    := \
	Common \
	Common/Equality \
	Common/Monad \
	Common/ReservedNotations \
	Common/ilist \
	Common/i2list \
	Common/ilist2 \
	Common/i2list2 \
	Common/StringBound \
	Common/DecideableEnsembles \
	Common/IterateBoundedIndex \
	Common/BoolFacts \
	Common/List/ListFacts \
	Common/List/FlattenList \
	Common/List/ListMorphisms \
	Common/List/PermutationFacts \
	Common/List/Prefix \
	Common/List/Operations \
	Common/List/UpperBound \
	Common/LogicFacts \
	Common/NatFacts \
	Common/LogicMorphisms \
	Common/Ensembles \
	Common/Ensembles/EnsembleListEquivalence \
	Common/Ensembles/Cardinal \
	Common/Ensembles/IndexedEnsembles \
	Common/Ensembles/Equivalence \
	Common/Ensembles/Morphisms \
	Common/Ensembles/Tactics \
	Common/Ensembles/CombinatorLaws \
	Common/Ensembles/Notations \
	Common/String_as_OT \
	Common/FMapExtensions \
	Common/SetEq \
	Common/SetEqProperties \
	ComputationalEnsembles \
	ComputationalEnsembles/Core \
	ComputationalEnsembles/Laws \
	ComputationalEnsembles/Morphisms \
	Computation/Notations \
	Computation/Core \
	Computation/Monad \
	Computation/LogicLemmas \
	Computation/SetoidMorphisms \
	Computation/ApplyMonad \
	Computation/Refinements/General \
	Computation/Refinements/Tactics \
	Computation \
	ADT/ADTSig \
	ADT/Core \
	ADT/ADTHide \
	ADT/ComputationalADT \
	ADT \
	Common/Wf \
	Common/Le \
	Common/UIP \
	ADTNotation/BuildADTSig \
	ADTNotation/BuildADT \
	ADTNotation/BuildComputationalADT \
	ADTNotation/BuildADTReplaceMethods \
	ADTNotation \
	ADTRefinement/Core \
	ADTRefinement/SetoidMorphisms \
	ADTRefinement/BuildADTSetoidMorphisms \
	ADTRefinement/GeneralRefinements \
	ADTRefinement/GeneralBuildADTRefinements \
	ADTRefinement \
	ADTRefinement/Refinements/DelegateMethods \
	ADTRefinement/Refinements/HoneRepresentation \
	ADTRefinement/Refinements/SimplifyRep \
	ADTRefinement/Refinements/ADTRepInv \
	ADTRefinement/Refinements/ADTCache \
	ADTRefinement/Refinements/RefineHideADT \
	ADTRefinement/Refinements \
	ADTRefinement/BuildADTRefinements/HoneRepresentation \
	ADTRefinement/BuildADTRefinements/SimplifyRep \
	ADTRefinement/BuildADTRefinements/AddCache \
	ADTRefinement/BuildADTRefinements

SRC_PARSERS_BASE_MODULES := \
	Parsers/ContextFreeGrammar\
	Parsers/ContextFreeGrammarProperties\
	Parsers/ContextFreeGrammarNotations\
	Parsers/Grammars/Trivial\
	Parsers/Grammars/ABStar\
	Parsers/Grammars/ExpressionNumPlus\
	Parsers/Grammars/ExpressionParen\
	Parsers/Grammars/ExpressionNumPlusParen
	Parsers/StringLike\
	Parsers/StringLike/Core\
	Parsers/StringLike/Properties\
	Parsers/StringLike/Examples\
	Parsers/BaseTypes\
	Parsers/BooleanBaseTypes\
	Parsers/Splitters/RDPList\
	Parsers/Splitters/BruteForce\
	Parsers/Splitters/Reflective\
	Parsers/Splitters/FirstChar\
	Parsers/Splitters/OnlyOneNonterminal\
	Parsers/DependentlyTyped\
	Parsers/DependentlyTypedOption\
	Parsers/DependentlyTypedSum\
	Parsers/DependentlyTypedMinimal\
	Parsers/DependentlyTypedMinimalOfParse\
	Parsers/DependentlyTypedMinimalOfParseFactored\
	Parsers/DependentlyTypedMinimalOfParseFactoredFull\
	Parsers/BooleanRecognizer\
	Parsers/WellFoundedParse\
	Parsers/MinimalParse\
	Parsers/MinimalParseOfParse\
	Parsers/BooleanRecognizerCorrect


COQDEP=coqdep
COQDOC=coqdoc
CITO_ARGS=

UNPREFIXED_CORE_VS := $(CORE_MODULES:%=%.v)
UNPREFIXED_CORE_VOS:= $(CORE_MODULES:%=%.vo)
UNPREFIXED_CORE_VD := $(CORE_MODULES:%=%.v.d)

CORE_VS := $(CORE_MODULES:%=src/%.v)
CORE_VOS:= $(CORE_MODULES:%=src/%.vo)
CORE_VDS:= $(CORE_MODULES:%=src/%.v.d)

COMPILER_VS  := $(COMPILER_MODULES:%=src/%.v)
COMPILER_VDS := $(COMPILER_MODULES:%=src/%.v.d)
COMPILER_VOS := $(COMPILER_MODULES:%=src/%.vo)

QUERYSTRUCTURE_VS  := $(QUERYSTRUCTURE_MODULES:%=src/%.v)
QUERYSTRUCTURE_VDS := $(QUERYSTRUCTURE_MODULES:%=src/%.v.d)
QUERYSTRUCTURE_VOS := $(QUERYSTRUCTURE_MODULES:%=src/%.vo)

SRC_PARSERS_VS  := $(SRC_PARSERS_MODULES:%=src/%.v)
SRC_PARSERS_VDS := $(SRC_PARSERS_MODULES:%=src/%.v.d)
SRC_PARSERS_VOS := $(SRC_PARSERS_MODULES:%=src/%.vo)
PREFIXED_SRC_PARSERS_VOS:= $(SRC_PARSERS_MODULES:%=src/%.vo)

SRC_PARSERS_BASE_VS  := $(SRC_PARSERS_BASE_MODULES:%=src/%.v)
SRC_PARSERS_BASE_VDS := $(SRC_PARSERS_BASE_MODULES:%=src/%.v.d)
SRC_PARSERS_BASE_VOS := $(SRC_PARSERS_BASE_MODULES:%=src/%.vo)
PREFIXED_SRC_PARSERS_BASE_VOS:= $(SRC_PARSERS_BASE_MODULES:%=src/%.vo)

ICS_VS  := $(ICS_MODULES:%=examples/%.v)
ICS_VDS := $(ICS_MODULES:%=examples/%.v.d)
ICS_VOS := $(ICS_MODULES:%=examples/%.vo)

DNS_VS  := $(DNS_MODULES:%=examples/%.v)
DNS_VDS := $(DNS_MODULES:%=examples/%.v.d)
DNS_VOS := $(DNS_MODULES:%=examples/%.vo)

FINITESET_VS  := $(FINITESET_MODULES:%=src/%.v)
FINITESET_VDS := $(FINITESET_MODULES:%=src/%.v.d)
FINITESET_VOS := $(FINITESET_MODULES:%=src/%.vo)

EXAMPLE_VS := $(EXAMPLE_MODULES:%=examples/%.v)
EXAMPLE_VOS:= $(EXAMPLE_MODULES:%=examples/%.vo)

V = 0

SILENCE_COQC_0 = @echo "COQC $<"; #
SILENCE_COQC_1 =
SILENCE_COQC = $(SILENCE_COQC_$(V))

SILENCE_COQDEP_0 = @echo "COQDEP $<"; #
SILENCE_COQDEP_1 =
SILENCE_COQDEP = $(SILENCE_COQDEP_$(V))

SILENCE_OCAMLC_0 = @echo "OCAMLC $<"; #
SILENCE_OCAMLC_1 =
SILENCE_OCAMLC = $(SILENCE_OCAMLC_$(V))

SILENCE_OCAMLDEP_0 = @echo "OCAMLDEP $<"; #
SILENCE_OCAMLDEP_1 =
SILENCE_OCAMLDEP = $(SILENCE_OCAMLDEP_$(V))

SILENCE_OCAMLOPT_0 = @echo "OCAMLOPT $<"; #
SILENCE_OCAMLOPT_1 =
SILENCE_OCAMLOPT = $(SILENCE_OCAMLOPT_$(V))

Q_0 := @
Q_1 :=
Q = $(Q_$(V))

VECHO_0 := @echo
VECHO_1 := @true
VECHO = $(VECHO_$(V))

TIMED=
TIMECMD=
STDTIME?=/usr/bin/time -f "$* (real: %e, user: %U, sys: %S, mem: %M ko)"
TIMER=$(if $(TIMED), $(STDTIME), $(TIMECMD))

COQDOCFLAGS=-interpolate -utf8

FAST_TARGETS := clean archclean printenv clean-old package-parsing-parses

.PHONY: all fiat querystructures parsers finitesets dns examples html clean pretty-timed pretty-timed-files pdf doc clean-doc cheat parsers-base package-parsing-parses

all : fiat querystructures parsers finitesets examples

fiat : $(CORE_VOS)

querystructures : $(QUERYSTRUCTURE_VOS)

finitesets : $(FINITESET_VOS)

examples : $(EXAMPLE_VOS)

compiler : $(COMPILER_VOS)

ics : $(ICS_VOS) examples/Ics/WaterTank.ml

examples/Ics/WaterTank.ml: $(ICS_VOS) examples/Ics/WaterTankExtract.v
	coqc -R src ParsingParses >$@

dns : $(DNS_VOS)

parsers : $(PREFIXED_SRC_PARSERS_VOS)

parsers-base : $(PREFIXED_SRC_PARSERS_BASE_VOS)

pdf: Overview/ProjectOverview.pdf Overview/library.pdf

doc: pdf html

-include Makefile.package-parsing-parses

Overview/library.tex: all.pdf
	cp "$<" "$@"

Overview/coqdoc.sty: all.pdf
	cp coqdoc.sty "$@"

Overview/library.pdf: Overview/library.tex Overview/coqdoc.sty
	cd Overview; pdflatex library.tex

Overview/ProjectOverview.pdf: $(shell find Overview -name "*.tex" -o -name "*.sty" -o -name "*.cls" -o -name "*.bib") Overview/library.pdf
	cd Overview; pdflatex -interaction=batchmode -synctex=1 ProjectOverview.tex || true
	cd Overview; bibtex ProjectOverview
	cd Overview; pdflatex -interaction=batchmode -synctex=1 ProjectOverview.tex || true
	cd Overview; pdflatex -synctex=1 ProjectOverview.tex

Makefile.coq: Makefile
	$(VECHO) "COQ_MAKEFILE > $@"
	$(Q)"$(COQBIN)coq_makefile" $(CORE_VS) $(EXAMPLE_VS) $(QUERYSTRUCTURE_VS) $(SRC_PARSERS_VS) $(FINITESET_VS) $(COMPILER_VS) COQC = "\$$(SILENCE_COQC)\$$(TIMER) \"\$$(COQBIN)coqc\"" COQDEP = "\$$(SILENCE_COQDEP)\"\$$(COQBIN)coqdep\" -c" COQDOCFLAGS = "$(COQDOCFLAGS)" -arg -dont-load-proofs -R src ParsingParses | sed s'/^\(-include.*\)$$/ifneq ($$(filter-out $(FAST_TARGETS),$$(MAKECMDGOALS)),)~\1~else~ifeq ($$(MAKECMDGOALS),)~\1~endif~endif/g' | tr '~' '\n' | sed s'/^clean:$$/clean-old::/g' | sed s'/^Makefile: /Makefile-old: /g' > $@

-include Makefile.coq

# overwrite OCAMLC, OCAMLOPT, OCAMLDEP to make `make` quieter
OCAMLC_OLD := $(OCAMLC)
OCAMLC = $(SILENCE_OCAMLC)$(OCAMLC_OLD)

OCAMLDEP_OLD := $(OCAMLDEP)
OCAMLDEP = $(SILENCE_OCAMLDEP)$(OCAMLDEP_OLD)

OCAMLOPT_OLD := $(OCAMLOPT)
OCAMLOPT = $(SILENCE_OCAMLOPT)$(OCAMLOPT_OLD)

clean::
	$(VECHO) "RM *.CMO *.CMI *.CMA"
	$(Q)rm -f $(ALLCMOFILES) $(CMIFILES) $(CMAFILES)
	$(VECHO) "RM *.CMX *.CMXS *.CMXA *.O *.A"
	$(Q)rm -f $(ALLCMOFILES:.cmo=.cmx) $(CMXAFILES) $(CMXSFILES) $(ALLCMOFILES:.cmo=.o) $(CMXAFILES:.cmxa=.a)
	$(VECHO) "RM *.ML.D *.MLI.D *.ML4.D *.MLLIB.D"
	$(Q)rm -f $(addsuffix .d,$(MLFILES) $(MLIFILES) $(ML4FILES) $(MLLIBFILES) $(MLPACKFILES))
	$(VECHO) "RM *.VO *.VI *.G *.V.D *.V.BEAUTIFIED *.V.OLD"
	$(Q)rm -f $(VOFILES) $(VIFILES) $(GFILES) $(VFILES:.v=.v.d) $(VFILES:=.beautified) $(VFILES:=.old)
	$(VECHO) "RM *.PS *.PDF *.GLOB *.TEX *.G.TEX"
	$(Q)rm -f all.ps all-gal.ps all.pdf all-gal.pdf all.glob $(VFILES:.v=.glob) $(VFILES:.v=.tex) $(VFILES:.v=.g.tex) all-mli.tex
	- rm -rf html mlihtml
	rm -f Makefile.coq .depend

clean-doc::
	rm -rf html
	rm -f all.pdf Overview/library.pdf Overview/ProjectOverview.pdf Overview/coqdoc.sty coqdoc.sty
	rm -f $(shell find Overview -name "*.log" -o -name "*.aux" -o -name "*.bbl" -o -name "*.blg" -o -name "*.synctex.gz" -o -name "*.out" -o -name "*.toc")
