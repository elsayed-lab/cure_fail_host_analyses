#!/usr/bin/env bash
start=$(pwd)
## commit="b8029c917589c904fe44891b2c81ccd8356d7941"
log=/setup_hpgltools.stdout
err=/setup_hpgltools.stderr
prefix="/sw/local/conda/${VERSION}"
cpus=$(cat /proc/cpuinfo | grep -c processor)
echo "Starting setup_hpgltools, downloading required headers and utilities." | tee -a ${log}

## The following installation is for stuff needed by hpgltools, these may want to be moved
## to the following mamba stanza
apt-get -y install libharfbuzz-dev libfribidi-dev libjpeg-dev libxft-dev libfreetype6-dev \
        libmpfr-dev libnetcdf-dev libtiff-dev wget 1>/dev/null 2>&1
apt-get clean

echo "Installing mamba with hpgltools env to ${prefix}." | tee -a ${log}
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -axvj bin/micromamba | tee -a ${log}
echo "Performing create env to ${prefix}." | tee -a ${log}
micromamba --root-prefix="${prefix}" --yes create -n hpgltools \
           imagemagick mpfr netcdf4 pandoc r-base=4.3.1 r-devtools r-tidyverse \
           -c conda-forge 1>/dev/null 2>>${err}
echo "Activating hpgltools" | tee -a ${log}
source /usr/local/etc/bashrc
## Beginning hpgltools installation.
## One might reasonably ask why I do not have a Rprofile ready to be copied by the
## docker/singularity bootstrap process.  I am not sure I can trust docker/singularity to not change the
## container's ${HOME}, and I know R will look there. So I am just putting the text I want here.
echo "options(Ncpus=24)" > "${HOME}/.Rprofile"
echo "options(timeout=600)" >> "${HOME}/.Rprofile"
echo "options(repos='https://cloud.r-project.org')" >> "${HOME}/.Rprofile"
echo "Downloading and installing hpgltools and prerequisites." | tee -a ${log}
git clone https://github.com/abelew/hpgltools.git 2>/dev/null 1>&2
cd hpgltools || exit

##echo "Explicitly setting to the commit which was last used for the analyses."
##git reset ${commit} --hard

## It turns out I cannot allow R to install the newest bioconductor version arbitrarily because
## not every package gets checked immediately, this caused everything to explode!
echo "Installing bioconductor version ${BIOC_VERSION}."
Rscript -e "install.packages('BiocManager', repo='http://cran.rstudio.com/')" 2>/dev/null 1>&2
Rscript -e "BiocManager::install(version='${BIOC_VERSION}', ask=FALSE)" 2>/dev/null 1>&2

echo "Installing non-base R prerequisites, essentially tidyverse." | tee -a ${log}
Rscript -e "BiocManager::install(c('devtools', 'tidyverse'), force=TRUE, update=TRUE, ask=FALSE)" 2>/dev/null 1>&2

echo "Installing the Depends packages via devtools." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Depends")' 2>/dev/null 1>&2
echo "Installing the Imports packages via devtools." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Imports")' 2>/dev/null 1>&2
echo "Installing the Suggests packages via devtools." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Suggests")' 2>/dev/null 1>&2

## preprocessCore has a bug which is triggered from within containers...
## https://github.com/Bioconductor/bioconductor_docker/issues/22
echo "Installing preprocessCore without threading to get around a container-specific bug." | tee -a ${log}
Rscript -e "BiocManager::install('preprocessCore', configure.args=c(preprocessCore='--disable-threading'), ask=FALSE, force=TRUE, update=TRUE, type='source')" 2>/dev/null 1>&2

## It appears the ggtree package is having troubles...
echo "Installing a dev version of ggtree due to weirdo errors, this is super annoying." | tee -a ${log}
Rscript -e 'remotes::install_github("YuLab-SMU/ggtree")' 2>/dev/null 1>&2
echo "In my last revision I got weird clusterProfiler loading errors, testing it out here." | tee -a ${log}
Rscript -e 'BiocManager::install(c("DOSE", "clusterProfiler"), force=TRUE, update=TRUE, ask=FALSE)' 2>/dev/nulll 1>&2

## I like these sankey plots and vennerable, but they are not in bioconductor.
echo "Installing ggsankey and vennerable." | tee -a ${log}
Rscript -e 'devtools::install_github("davidsjoberg/ggsankey")' 1>/dev/null 2>&1
Rscript -e 'devtools::install_github("js229/Vennerable")' 1>/dev/null 2>&1
## The new version of dbplyr is broken and causes my annotation download to fail, and therefore _everything_ else.
Rscript -e 'devtools::install_version("dbplyr", version="2.3.4", repos="http://cran.us.r-project.org")' 1>/dev/null 2>&1

echo "Updating all packages to bioconductor release: ${BIOC_VERSION}" | tee -a ${log}
Rscript -e 'BiocManager::install(), force=TRUE, update=TRUE, ask=FALSE)' 1>/dev/null 2>&1

echo "Installing hpgltools itself." | tee -a ${log}
R CMD INSTALL . 1>/dev/null 2>&1

cd ${start} || exit
