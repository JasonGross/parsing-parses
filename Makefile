COQDEP=coqdep
COQDOC=coqdoc

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

FAST_TARGETS := Makefile.coq clean archclean printenv clean-old

.PHONY: default all html clean

default: all

Makefile.coq: Makefile _CoqProject
	$(VECHO) "COQ_MAKEFILE > $@"
	$(Q)"$(COQBIN)coq_makefile" -f _CoqProject COQC = "\$$(SILENCE_COQC)\$$(TIMER) \"\$$(COQBIN)coqc\"" COQDEP = "\$$(SILENCE_COQDEP)\"\$$(COQBIN)coqdep\" -c" | sed s'/^\(-include.*\)$$/ifneq ($$(filter-out $(FAST_TARGETS),$$(MAKECMDGOALS)),)~\1~else~ifeq ($$(MAKECMDGOALS),)~\1~endif~endif/g' | tr '~' '\n' | sed s'/^clean:$$/clean-old::/g' | sed s'/^Makefile: /Makefile-old: /g' > $@

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
