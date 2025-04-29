#!/usr/bin/env sh

##############################################################################
# 1) Activate data_download env
##############################################################################
if command -v micromamba >/dev/null 2>&1; then
  eval "$(micromamba shell hook --shell posix)"
  micromamba activate data_download
elif command -v mamba >/dev/null 2>&1; then
  eval "$(conda shell.posix hook)"
  conda activate data_download
elif command -v conda >/dev/null 2>&1; then
  eval "$(conda shell hook --shell posix)"
  conda activate data_download
else
  echo "Error: micromamba, mamba or conda not found" >&2
  exit 1
fi

##############################################################################
# 2) Paths & parallelism
##############################################################################
PARALLEL_DOWNLOADS=160                     # crank it back up when you’re happy
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(dirname "$script_dir")"
manifest_file="$project_root/download_data/TCGA_manifests/manifest.txt"
raw_root="$project_root/data/TCGA/raw"
mkdir -p "$raw_root"
mkdir -p "$raw_root/rnaseq"

##############################################################################
# 3) Download loop
##############################################################################
TARGET_DIRS=11094

echo "Manifest: $manifest_file"
[ -s "$manifest_file" ] || { echo "Manifest not found / empty"; exit 1; }

while :; do
  echo "Checking / downloading missing HTSeq counts…"

  # one fast pass over the manifest
  tail -n +2 "$manifest_file" | cut -f1,2 | \
    xargs --no-run-if-empty -n2 -P "$PARALLEL_DOWNLOADS" sh -c '
      uuid="$1"
      filename="$2"
      dir="'"$raw_root"'/$uuid"
      out="$dir/$filename"
      tmp="$out.part"
  
      # --- DEBUG ---------------------------------------------------
      echo "→ uuid=$uuid  file=$filename" >&2
      # -------------------------------------------------------------
  
      mkdir -p "$dir"
      [ -s "$out" ] && { echo "✔ already have $uuid/$filename" >&2; exit 0; }
  
      curl -L "https://api.gdc.cancer.gov/data/$uuid" \
           --retry 5 --retry-delay 5 --retry-connrefused \
           --connect-timeout 15 --max-time 300 \
           -C - -o "$tmp" \
           --silent --show-error \
        && mv "$tmp" "$out" \
        && echo "✓ downloaded $uuid/$filename" >&2 \
        || { echo "✗ failed $uuid/$filename" >&2; rm -f "$tmp"; exit 1; }
      ' _


  dir_count=$(find "$raw_root" -mindepth 1 -maxdepth 1 -type d | wc -l)
  empty_count=$(find "$raw_root" -mindepth 1 -maxdepth 1 -type d -empty | wc -l)

  if [ "$dir_count" -ge "$TARGET_DIRS" ] && [ "$empty_count" -eq 0 ]; then
    echo "All HTSeq counts downloaded – $dir_count folders present (target $TARGET_DIRS)."
    break
  fi

  echo "Currently $dir_count / $TARGET_DIRS folders present – retrying in 5 s…"
  sleep 5
done

##############################################################################
# 4) Supplementary response ZIP (download once)
##############################################################################
supp_url="https://oup.silverchair-cdn.com/oup/backfile/Content_public/Journal/bioinformatics/32/19/10.1093_bioinformatics_btw344/5/bioinformatics_32_19_2891_s1.zip?Expires=1748964625&Signature=aqDHR-LcwgY24jrMkYLaJQf2Ba12tb6IJjgs-1KpNGJRmviNnP2VAlB2htJ752eYWTMGEN-Q-cLalk4DarKsR2SLTgpHhFDYvmLhQkTSfxNpTtoo36d~LKMpN9W4DUdRjWS2dYU1~9A8r9E8nZ5XIQzbjZDOx7LpY7bk31OceCN57VfC-U9GFh-obWVXpKk~xK6Va~yFI1cdCdzDkT4kkZ9oNognrClMkXsyxO0vQbPpLP8pU6bOP8JctGa6Beslk8jAkCjEP5DQ8pBotEhKJ0YJe38NnW435Z0rHob7eDW2gWdVsrq6ooaYh9PD~Tf~T17dtnLhvb-ntkE2h6kV9g__&Key-Pair-Id=APKAIE5G5CRDK6RD3PGA"
resp_zip="$raw_root/response.zip"

if [ -s "$resp_zip" ] && unzip -t "$resp_zip" >/dev/null 2>&1; then
  echo "Supplementary ZIP already present and valid."
else
  echo "Downloading supplementary response ZIP…"
  wget -q -O "$resp_zip" "$supp_url"
  unzip -o "$resp_zip" -d "$raw_root"
fi

##############################################################################
# 5) Down-stream processing
##############################################################################
python "$script_dir/TCGA_dependencies/download_TCGA.py"
python "$script_dir/TCGA_dependencies/process_TCGA.py"

