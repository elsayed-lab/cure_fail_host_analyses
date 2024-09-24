.PHONY: graph

TARGET = cure_fail_host_analyses.sif

BIB = ${HOME}/Documents/bibtex/atb.bib

all: $(TARGET)

RMD_FILES = data/*.Rmd

SETUP_SCRIPTS = local/bin/*.sh

CONFIG_FILES = local/etc/*

## If your machine has less than ~ 180G ram, you may need to set this to FALSE
PARALLEL="TRUE"
DEFAULT_INPUT="00preprocessing.Rmd:01datasets.Rmd:02visualization.Rmd:03differential_expression_both.Rmd:04differential_expression_tumaco.Rmd:05enrichment.Rmd:06lrt_gsva.Rmd:07wgcna.Rmd:08classifier_highvar.Rmd:README.Rmd"

## Note x,y is multiple binds, a:b binds host:a to container:b
SINGULARITY_BIND="/sw/local/R/renv_cache"

%.sif: %.yml $(RMD_FILES) $(SETUP_SCRIPTS) $(CONFIG_FILES) $(BIB)
	touch data/atb.bib
	cp local/etc/bashrc_template local/etc/bashrc
	echo "export PARALLEL=$(PARALLEL)" >> local/etc/bashrc
	echo "export DEFAULT_INPUT=$(DEFAULT_INPUT)" >> local/etc/bashrc
	test -f $(BIB) && cp $(BIB) data/atb.bib
	sudo singularity build -B $(SINGULARITY_BIND) --force $@ $<

%.overlay: %.yml
	mkdir -p $(basename $<)_overlay
	sudo singularity shell -B $(SINGULARITY_BIND) --overlay $(basename $@)_overlay $(basename $@).sif

%.shell: %.yml
	singularity shell -B $(SINGULARITY_BIND) $(basename $@).sif

%.runover: %.yml
	mkdir -p $(basename $<)_overlay
	sudo singularity run -B $(SINGULARITY_BIND) --overlay $(basename $@)_overlay $(basename $@).sif

graph:
	make -dn MAKE=: all | sed -rn "s/^(\s+)Considering target file '(.*)'\.$/\1\2/p"
