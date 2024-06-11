# Introduction

Define, create, and run the analyses used in the paper:
"Innate Biosignature of Treatment Failure in Human Cutaneous Leishmaniasis."

This repository contains everything one should need to create a
singularity container which is able to run all of the various R
tasks performed, recreate the raw images used in the figures, create
the various intermediate rda files for sharing with others, etc.  In
addition, one may use the various singularity shell commands to enter
the container and play with the data.

# Installation

Grab a copy of the repository:

```{bash, eval=FALSE}
git pull https://github.com/elsayed-lab/cure_fail_host_analyses.git
```

The resulting directory should contain a few subdirectories of note:

* local: Contains the configuration information and setup scripts for the
  container and software inside it.
* data: Numerically sorted R markdown files which contain all the fun
  stuff.  Look here first.
* preprocessing: Archives of the count tables produced when using cyoa
  to process the raw sequence data. Once we have accessions for SRA, I
  will finish the companion container which creates these.
* sample_sheets: A series of excel files containing the experimental
  metadata we collected over time.  In some ways, these are the most
  important pieces of this whole thing.

At the root, there should also be a yml and Makefile which contain the
definition of the container and a few shortcuts for
building/running/playing with it.

# Creating the container

With either of the following commands, singularity should read the yml
file and build a Debian stable container with a R environment suitable
for running all of the analyses in Rmd/.

```{bash, eval=FALSE}
make
## Really, this just runs:
sudo -E singularity build tmrc3_analyses.sif tmrc3_analyses.yml
```

The default Makefile target has dependencies for all of the .Rmd files
in data/; so if any of them change it should rebuild.

# Generating the html/rda/excel output files

One of the neat things about singularity is the fact that one may just
'run' the container and it will execute the commands in its
'%runscript' section.  That runscript should use knitr to render a
html copy of all the Rmd/ files and put a copy of the html outputs
along with all of the various excel/rda/image outputs into the current
working directory of the host system.

```{bash, eval=FALSE}
./cure_fail_host_analyses.sif
```

# Playing around inside the container

If, like me, you would rather poke around in the container and watch
it run stuff, either of the following commands should get you there:

```{bash, eval=FALSE}
make tmrc3_analyses.overlay
## That makefile target just runs:
mkdir -p tmrc3_analyses_overlay
sudo singularity shell --overlay tmrc3_analyses_overlay tmrc3_analyses.sif
```

### The container layout and organization

When the runscript is invoked, it creates a directory in $(pwd) named
YYYYMMDDHHmm_outputs/ and rsync's a copy of my working tree into it.
This working tree resides in /data/ and comprises the following:

* samplesheets/ : xlsx files containing the metadata collected and
  used when examining the data.  It makes me more than a little sad
  that we continue to trust this most important data to excel.
* preprocessing/ : The tree created by cyoa during the processing of
  the raw data downloaded from the various sequencers used during the
  project.  Each directory corresponds to one sample and contains all
  the logs and outputs of every program used to play with the data.
  In the context of the container this is relatively limited due to
  space constraints.
* renv/ and renv.lock : The analyses were all performed using a
  specific R and bioconductor release on my workstation which the
  container attempts to duplicate.  If one wishes to create an R
  environment on one's actual host which duplicates every version of
  every package installed, these files provide that ability.
* The various .Rmd files : These are numerically named analysis files.
  The 00preprocessing does not do anything, primarily because I do not
  think anyone wants a 6-10Tb container (depending on when/what is
  cleaned during processing)!  All files ending in _commentary are
  where I have been putting notes and muttering to myself about what
  is happening in the analyses.  01datasets is the parent of all the
  other files and is responsible for creating the data structures
  which are used in every file which follows.  The rest of the files
  are basically what they say on the tin: 02visualization has lots of
  pictures, 03differential_expression* comprises DE analyses of
  various data subsets, 04lrt_gsva combines a series of likelihood
  ratio tests and GSVA analyses which were used (at least by me) to
  generate hypotheses and look for other papers which have similar gene
  signatures (note that the GSVA analysis in the container does not
  include the full mSigDB metadata and so is unlikely to include all
  the paper references, I did include the code blocks which use the
  full 7.2 data, so it should be trivial to recapitulate that if one
  signs up a Broad and downloads the relevant data).  05wgcna is a
  copy of Alejandro's WGCNA work with some minor modifications.
  06classifier* is a series of documents I wrote to learn how to play
  with ML classifiers and was explicitly intended to not be published,
  but just a fun exercise.  07varcor_regression is a copy of Theresa's
  work to examine correlations between various metadata factors,
  surrogate variables, and her own explorations in ML; again with some
  minor changes which I think I noted.
* /usr/local/bin/* : This comprises the bootstrap scripts used to
  create the container and R environment, the runscript.sh used to run
  R/knitr on the Rmd documents, and some configuration material in
  etc/ which may be used to recapitulate this environment on a
  bare-metal host.

```{bash, eval=FALSE}
## From within the container
cd /data
## Copy out the Rmd files to a directory where you have permissions via $SINGULARITY_BIND
## otherwise you will get hit with a permissions hammer.
## Or invoke the container with an overlay.
emacs -nw 01datasets.Rmd
## Render your own copy of the data:
Rscript -e 'rmarkdown::render("01datasets.Rmd")'
## If you wish to get output files with the YYYYMM date prefix I use:
Rscript -e 'hpgltools::renderme("01datasets.Rmd")'
```
