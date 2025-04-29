#!/bin/sh

# Detect available installer and initialize shell hook
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

# Create & activate the environment
$PM create -n data_download python=3.8 -y
$PM activate data_download

# Install utilities and data-processing dependencies
$PM install -y -c anaconda virtualenv \
                -c conda-forge xlrd=1.2.0 pandas numpy openpyxl joblib unzip

$PM install -y openpyxl

# Install extra Python bits for TCGA scripts
pip install -r ./TCGA_dependencies/requirements.txt

# Build & install the GDC client
git clone https://github.com/NCI-GDC/gdc-client.git
cd gdc-client
pip install -r requirements.txt
python setup.py install
cd bin && ./package
unzip *.zip
cd ..
cd ..

