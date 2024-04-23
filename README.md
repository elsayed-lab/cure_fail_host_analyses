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
git pull something something
```

The resulting directory should contain a few subdirectories of note:

* bin: Contains the setup scripts for the container and software
  inside it.
* data: Numerically sorted R markdown files which contain all the fun
  stuff.  Look here first.
* dotemacs.d: Probably only of interest to me, I use emacs and it
  allows me to play with the analyses interactively.
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
make tmrc3_analyses.sif
## Really, this just runs:
sudo -E singularity build tmrc3_analyses.sif tmrc3_analyses.yml
```

# Generating the html/rda/excel output files

One of the neat things about singularity is the fact that one may just
'run' the container and it will execute the commands in its
'%runscript' section.  That runscript should use knitr to render a
html copy of all the Rmd/ files and put a copy of the html outputs
along with all of the various excel/rda/image outputs into the current
working directory of the host system.  In order for this to work, it
makes one bit assumption: the environment variable
SINGULARITY_BINDPATH _must_ include '.:/output'.

One may of course change $PWD to wherever one wishes, as well as add
more comma-separated paths.  With that in mind, the following should
run for a few hours and print a whole lot of text to the screen, then
dump a lot of files to ${PWD}/{current_date}_outputs.

*NOTE: 202309* I did not think through the implications of the
immutable nature of the singularity container.  I knew that the images
are RO, but for some reason I still assumed I can write to it in the
run script.  As a result, until I more fully understand singularity,
the following will not work.  I think the key thing I must do is
create a sandbox image, but until I figure it out, it will likely
easiest to use an overlay.

```{bash, eval=FALSE}
export SINGULARITY_BINDPATH=".:/output"
./tmrc3_analyses.sif
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

## Playing around inside the container

All of the fun stuff is in /data.  The container has a working vim and
emacs installation, so go nuts. I also put a portion of my emacs
config sufficient to play with R markdown files.

```{bash, eval=FALSE}
## From within the container
cd /data
emacs -nw 01datasets.Rmd
## Render your own copy of the data:
Rscript -e 'hpgltools::renderme("01datasets.Rmd")'
cp *datasets*.html /output/
```

If you used the SINGULARITY_BIND environment variable as noted above,
then any files you copy to /output within the container should appear
at the current working directory of the host when you started it.  You
may also copy stuff to the other singularity binds like $HOME, but
since overlays require sudo, the results are likely to be inconsistent
and weird.

In addition, if you poke around in the tmrc3_analyses_overlay
directory, you will find copies of _any_ files which changed in the
container while it was running; so you may poke around in there to get
a more complete view of what happened while it was running.
