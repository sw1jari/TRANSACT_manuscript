#!/usr/bin/env zsh

# 1) Initialize micromamba in this shell
eval "$(micromamba shell hook --shell zsh)"

# 2) Create & activate the data_download env with Python 3.8
micromamba create -n data_download python=3.8 -y
micromamba activate data_download

# 3) Install basic utilities and data-processing dependencies
micromamba install -n data_download -y \
    -c anaconda virtualenv \
    -c conda-forge xlrd=1.2.0 pandas numpy openpyxl joblib \

# 4) Install any extra Python bits for the TCGA scripts
pip install -r ./TCGA_dependencies/requirements.txt

git clone https://github.com/NCI-GDC/gdc-client.git
cd gdc-client
pip install -r requirements.txt
python setup.py install
cd bin
./package
