#!/bin/sh

# 1) Create directories
mkdir -p ../data/GDSC/raw
mkdir -p ../data/GDSC/rnaseq ../data/GDSC/fpkm ../data/GDSC/response

# 2) Download raw RNA-seq and metadata
wget -P ../data/GDSC/raw https://cog.sanger.ac.uk/cmp/download/rnaseq_20191101.zip
unzip ../data/GDSC/raw/rnaseq_20191101.zip -d ../data/GDSC/raw/
rm ../data/GDSC/raw/rnaseq_20191101.zip

wget -P ../data/GDSC https://cog.sanger.ac.uk/cmp/download/model_list_20191104.csv

# 3) Activate data_download env (micromamba, mamba or conda)
if command -v micromamba >/dev/null 2>&1; then
  eval "$(micromamba shell hook --shell posix)"
  micromamba activate data_download
elif command -v mamba >/dev/null 2>&1; then
  eval "$(conda shell hook --shell posix)"
  mamba activate data_download
elif command -v conda >/dev/null 2>&1; then
  eval "$(conda shell hook --shell posix)"
  conda activate data_download
else
  echo "Error: micromamba, mamba or conda not found" >&2
  exit 1
fi

# 4) Process GDSC files
python ./GDSC_dependencies/process_GDSC.py

# 5) Download dose-response Excel files
wget -P ../data/GDSC/response ftp://ftp.sanger.ac.uk/pub/project/cancerrxgene/releases/release-8.2/GDSC1_fitted_dose_response_25Feb20.xlsx
wget -P ../data/GDSC/response ftp://ftp.sanger.ac.uk/pub/project/cancerrxgene/releases/release-8.2/GDSC2_fitted_dose_response_25Feb20.xlsx

# 6) Clean up raw folder
rm -rf ../data/GDSC/raw

