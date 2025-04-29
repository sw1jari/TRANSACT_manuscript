#!/usr/bin/env sh

# 1) Activate data_download env
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

# 2) Paths & parallelism
PARALLEL_DOWNLOADS=160
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(dirname "$script_dir")"
manifest_file="$project_root/download_data/TCGA_manifests/manifest.txt"
raw_root="$project_root/data/TCGA/raw"
mkdir -p "$raw_root"

# 3) Download loop: retry until no empty UUID folders remain
while find "$raw_root" -mindepth 1 -maxdepth 1 -type d -empty | grep -q .; do
  echo "Retrying missing HTSeq downloads…"
  tail -n +2 "$manifest_file" | cut -f1,2 | \
    xargs -n2 -P "$PARALLEL_DOWNLOADS" sh -c '
      uuid="$0"; filename="$1"
      dir="'"$raw_root"'/$uuid"
      out="$dir/$filename"
      tmp="$out.part"

      mkdir -p "$dir"
      [ -s "$out" ] && exit 0

      curl -L "https://api.gdc.cancer.gov/data/$uuid" \
           --retry 5 --retry-delay 5 --retry-connrefused \
           --connect-timeout 15 --max-time 300 \
           -C - -o "$tmp" \
           --silent --show-error \
        && mv "$tmp" "$out" \
        || { echo "✗ failed: $uuid/$filename"; rm -f "$tmp"; exit 1; }
    ' _

  # brief pause before re-checking
  sleep 5
done

echo "All HTSeq counts downloaded."

# 4) Supplementary response ZIP (download once)
supp_url="https://oup.silverchair-cdn.com/oup/backfile/Content_public/Journal/bioinformatics/32/19/10.1093_bioinformatics_btw344/5/bioinformatics_32_19_2891_s1.zip?Expires=...&Key-Pair-Id=..."
resp_zip="$raw_root/response.zip"

if [ -s "$resp_zip" ] && unzip -t "$resp_zip" >/dev/null 2>&1; then
  echo "Supplementary ZIP already present and valid."
else
  echo "Downloading supplementary response ZIP…"
  wget -O "$resp_zip" "$supp_url"
  unzip -o "$resp_zip" -d "$raw_root"
fi

# 5) Process with TRANSACT scripts
python "$script_dir/TCGA_dependencies/download_TCGA.py"
python "$script_dir/TCGA_dependencies/process_TCGA.py"

