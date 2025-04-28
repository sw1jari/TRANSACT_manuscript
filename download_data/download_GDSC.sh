#!/bin/sh
mkdir -p ../data/GDSC/raw
mkdir -p ../data/GDSC/rnaseq ../data/GDSC/fpkm ../data/GDSC/response

wget -P ../data/GDSC/raw https://cog.sanger.ac.uk/cmp/download/rnaseq_20191101.zip
unzip ../data/GDSC/raw/rnaseq_20191101.zip -d ../data/GDSC/raw/
rm ../data/GDSC/raw/rnaseq_20191101.zip

wget -P ../data/GDSC https://cog.sanger.ac.uk/cmp/download/model_list_20191104.csv

eval "$(micromamba shell hook --shell zsh)"  
micromamba activate data_download
python ./GDSC_dependencies/process_GDSC.py

wget -P ../data/GDSC/response ftp://ftp.sanger.ac.uk/pub/project/cancerrxgene/releases/release-8.2/GDSC1_fitted_dose_response_25Feb20.xlsx
wget -P ../data/GDSC/response ftp://ftp.sanger.ac.uk/pub/project/cancerrxgene/releases/release-8.2/GDSC2_fitted_dose_response_25Feb20.xlsx

rm -r ../data/GDSC/raw
