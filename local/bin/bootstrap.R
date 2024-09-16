#!/usr/bin/env Rscript
setwd("/data")
## This script will perform the installation of the various tools I want
## into a renv tree and save the results to a renv.lock file.
## Then it will deactivate so that the actual R session will work.

## Start with the bioconductor release from /versions.txt

## 'MHOM' is sufficiently distinct that it will get the L.panamensis MHOM/COL strain from tritrypdb.
eupath_strings <- c("MHOM")
github_pkgs <- c(
  "Bioconductor/AnnotationHubData", "js229/Vennerable", "YuLab-SMU/ggtree", "davidsjoberg/ggsankey"
)
local_pkgs <- c("hpgltools", "EuPathDB")
random_helpers <- c(
  "BSgenome", "CMplot", "devtools", "flashClust", "forestplot", "ggbio", "glmnet", "irr",
  "lares", "patchwork", "ranger", "renv", "rpart", "rpart.plot", "tidyverse", "xgboost")
specific_args <- list(
  "preprocessCore" = c(preprocessCore = "--disable-threading"))
specific_versions <- list(
  "dbplyr" = "2.3.4",
  "MASS" = "7.3-60",
  "Matrix" = "1.6-5",
  "rjson" = "0.2.21")
starter <- c("BiocManager", "remotes", "devtools")
stupidly_broken <- c("clusterProfiler")

message("Installing biocmanager and setting BIOC_VERSION.")
start <- install.packages(starter)
set <- BiocManager::install(version = Sys.getenv("BIOC_VERSION"))

## Install specific versions of some needed things which appear no longer to work
## in the current (202405) bioconductor release.
message("Installing a few packages which require specific versions to function.")
for (i in seq_along(specific_versions)) {
  pkg <- names(specific_versions)[i]
  ver <- specific_versions[i]
  message("Installing ", pkg, ", version: ", ver, ".")
  installedp <- try(devtools::install_version(pkg, version = ver))
}

for (i in local_pkgs) {
  dep_pkgs <- remotes::dev_package_deps(i, dependencies = "Depends")[["package"]]
  message("Installing Depends for ", i, ": ", toString(dep_pkgs))
  installedp <- try(BiocManager::install(dep_pkgs))
  import_pkgs <- remotes::dev_package_deps(i, dependencies = "Imports")[["package"]]
  message("Installing Imports for ", i, ": ", toString(import_pkgs))
  installedp <- try(BiocManager::install(import_pkgs))
  suggest_pkgs <- remotes::dev_package_deps(i, dependencies = "Suggests")[["package"]]
  message("Installing Suggests for ", i, ": ", toString(suggest_pkgs))
  installedp <- try(BiocManager::install(suggest_pkgs))
}

message("Install a few helper packages of interest that are not explicitly in my DESCRIPTION.")
installedp <- try(BiocManager::install(random_helpers))

message("Installing a few github packages.")
for (i in github_pkgs) {
  installedp <- try(devtools::install_github(i))
}

message("Installing local packages. (hpgltools and EuPathDB)")
for (i in local_pkgs) {
  installedp <- try(devtools::install(i))
}

message("Ensuring that the appropriate configure args are set when needed.")
for (i in seq_along(specific_args)) {
  pkg <- names(specific_args)[i]
  args <- specific_args[i]
  installedp <- try(BiocManager::install(pkg, configure.args=args,
                                         force = TRUE, update = TRUE, type = "source"))
}

#message("Iterating over the renv versions.")
#versions <- rjson::fromJSON(file = "renv.lock")
#wanted <- versions[[3]]
#installed <- installed.packages()
#num_pkgs <- length(wanted)
#for (pkg in seq_len(num_pkgs)) {
#  this <- installed[[pkg]]
#  name <- names(installed)[pkg]
#  version <- this[["Version"]]
#  if (name %in% installed) {
#    message(name, " is already installed.")
#  } else {
#    message("Installing ", name, " version ", version, ".")
#    installedp <- try(devtools::install_version(name, version = version))
#  }
#}

message("Installing desired eupathdb packages.")
for (i in eupath_strings) {
  meta <- EuPathDB::download_eupath_metadata(webservice = "tritrypdb")
  entry <- EuPathDB::get_eupath_entry(i, metadata = meta[["valid"]])
  org <- EuPathDB::make_eupath_orgdb(entry)
  bsg <- EuPathDB::make_eupath_bsgenome(entry)
  txdb <- EuPathDB::make_eupath_txdb(entry)
  grange <- EuPathDB::make_eupath_granges(entry)
}
## I am doing the snapshot before the EuPathDB creations because
## they will just confuse renv.
#message("Creating a renv json and lock.")
#renv::snapshot(prompt = FALSE, force = TRUE, exclude = c("hpgltools", "EuPathDB"))
