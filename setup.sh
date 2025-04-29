#!/usr/bin/env sh

# 1) Detect Conda-style manager and initialize shell hook
if command -v micromamba >/dev/null 2>&1; then
  eval "$(micromamba shell hook --shell posix)"
  micromamba activate data_download
elif command -v mamba >/dev/null 2>&1; then
  . "$(conda info --base)/etc/profile.d/conda.sh"
  mamba activate data_download
elif command -v conda >/dev/null 2>&1; then
  . "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate data_download
else
  echo "Error: micromamba, mamba or conda not found" >&2
  exit 1
fi

# 2) Create & activate the environment
$PM create -n transact_figures python=3.8 -y
$PM activate transact_figures

# 3) Install Python requirements and Jupyter kernel
pip install -r requirements.txt
pip install ipykernel
python -m ipykernel install --user --name transact_figures --display-name "Python (TRANSACT_figures)"

# 4) Install R and rpy2
$PM install -y -c r r=3.5.1 rpy2

# 5) Install miscellaneous Python packages
$PM install -y tzlocal
$PM install -y -c conda-forge umap-learn
pip install seaborn scikit-learn statannot torch skorch

# 6) Install edgeR via the provided script
python install_edgeR.py

# 7) Install the TRANSACT CLI library
pip install transact_dr

