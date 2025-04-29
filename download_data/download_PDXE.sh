#!/usr/bin/env sh

# 1) Create raw data folder
mkdir -p ../data/PDXE/raw

# 2) Download the PDXE Excel
wget -P ../data/PDXE/raw https://static-content.springer.com/esm/art%3A10.1038%2Fnm.3954/MediaObjects/41591_2015_BFnm3954_MOESM10_ESM.xlsx

# 3) Activate the data_download env (micromamba, mamba, or conda)
if command -v micromamba >/dev/null 2>&1; then
  # POSIX-sh hook for micromamba
  eval "$(micromamba shell hook -s posix)"
  micromamba activate data_download

elif command -v mamba >/dev/null 2>&1; then
  # POSIX-sh hook so mamba activate works in /bin/sh
  eval "$(conda shell.posix hook)"
  conda activate data_download

elif command -v conda >/dev/null 2>&1; then
  # POSIX-sh hook for conda
  eval "$(conda shell.posix hook)"
  conda activate data_download

else
  echo "Error: micromamba, mamba or conda not found" >&2
  exit 1
fi

# 4) Run the PDXE processing scripts
python ./PDXE_dependencies/download_PDXE.py
python ./PDXE_dependencies/process_PDXE.py

# 5) Clean up raw folder
rm -rf ../data/PDXE/raw

