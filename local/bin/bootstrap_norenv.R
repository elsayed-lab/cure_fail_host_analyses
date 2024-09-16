#!/usr/bin/env Rscript
setwd("/data")
eupath_strings <- c("MHOM")
message("Installing desired eupathdb packages.")
for (i in eupath_strings) {
  meta <- EuPathDB::download_eupath_metadata(webservice = "tritrypdb")
  entry <- EuPathDB::get_eupath_entry(i, metadata = meta[["valid"]])
  org <- EuPathDB::make_eupath_orgdb(entry)
  bsg <- EuPathDB::make_eupath_bsgenome(entry)
  txdb <- EuPathDB::make_eupath_txdb(entry)
  grange <- EuPathDB::make_eupath_granges(entry)
}

##BiocManager::install(version = Sys.getenv("BIOC_VERSION"))
