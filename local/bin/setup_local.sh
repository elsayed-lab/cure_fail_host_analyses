#!/usr/bin/env bash
start=$(pwd)
source /usr/local/etc/bashrc

log=/setup_local.stdout
err=/setup_local.stderr
echo "Installing a few ML packages." | tee -a ${log}
## Adding a few random packages used for rendering the ML classifier document.
Rscript -e 'BiocManager::install(c("glmnet", "ranger", "xgboost"))' 2>${err} 1>>${log}
## Adding a few random packages used for rendering the WGCNA document.
Rscript -e 'BiocManager::install(c("irr", "CorLevelPlot", "flashClust"))' 2>>${err} 1>>${log}
Rscript -e 'BiocManager::install("Heatplus")' | tee -a ${log}
## I have no idea why upsetr did not get installed, it is in the description
Rscript -e 'BiocManager::install("UpSetR")' | tee -a ${log}
