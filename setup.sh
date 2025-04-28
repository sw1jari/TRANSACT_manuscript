#!/bin/sh
# Activate Jupyter notebook
micromamba create -n transact_figures python=3.8
micromamba activate transact_figures
pip install -r requirements.txt
pip install ipykernel
micromamba install -c r r=3.5.1
micromamba install -c r rpy2
python -m ipykernel install --user --name transact_figures --display-name "Python (TRANSACT_figures)"
micromamba install tzlocal
micromamba install -c conda-forge umap-learn
pip install seaborn scikit-learn statannot torch skorch

# Install edgeR
# micromamba install -c bioconda bioconductor-edger
python install_edgeR.py

# Install TRANSACT
pip install transact_dr
