#!/usr/bin/env zsh

# Number of parallel downloads
PARALLEL_DOWNLOADS=160

# Paths
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(dirname "$script_dir")"
manifest_file="$project_root/download_data/TCGA_manifests/manifest.txt"
raw_root="$project_root/data/TCGA/raw"

mkdir -p "$raw_root"

echo "Downloading TCGA HTSeq files into $raw_root with up to $PARALLEL_DOWNLOADS parallel jobs…"

tail -n +2 "$manifest_file" | cut -f1,2 | \
  xargs -n2 -P "$PARALLEL_DOWNLOADS" sh -c '
    uuid="$0"; filename="$1"
    dir="'"$raw_root"'/$uuid"
    out="$dir/$filename"
    tmp="$out.part"

    mkdir -p "$dir"

    if [ -s "$out" ]; then
      # printf "✔ %s/%s exists, skipping\n" "$uuid" "$filename"
      exit 0
    fi

    # printf "↓ %s → %s\n" "$uuid" "$filename"
    curl -L "https://api.gdc.cancer.gov/data/$uuid" \
         --retry 5 --retry-delay 5 --retry-connrefused \
         --connect-timeout 15 --max-time 300 \
         -C - -o "$tmp" \
         --silent --show-error \
      && mv "$tmp" "$out" \
      || { printf "✗ %s/%s failed\n" "$uuid" "$filename"; rm -f "$tmp"; exit 1; }
  '  

echo "Done downloading all HTSeq counts."

# Supplement can be changed and retrieved from here https://academic.oup.com/bioinformatics/article/32/19/2891/2196464#supplementary-data
wget -O $raw_root'/response.zip' "https://oup.silverchair-cdn.com/oup/backfile/Content_public/Journal/bioinformatics/32/19/10.1093_bioinformatics_btw344/5/bioinformatics_32_19_2891_s1.zip?Expires=1748899118&Signature=xnfY8nGPB-W2AqGcKKhX4gRH2M~rchPtT6jrQhGmgqLSR3pZ85GtHBer05kkZXov7SmF6wVeD8lxJwVPvIUvkGeqKXBZ~o5m1xRem~~6sZk97dJGUchMxlJhFcGggD~7LXXwZRJ606AqWa-K4xVMUaaoRCXkSVLMmZidVIfTArZvQ98~ZVpAQFe6qkV96PhETUR56NWpq5SqLSFgJNCQtmHe64ALaCcxWV1b4S3yfKQwdgHMHwtQjtyaRJ0rPuF0EyqT6U7tJAjEvTpsFODUxqX3u1Mvq~Aa~lgOoQrxJbYZIhFWE7PiauqEkdDGC-RzGEYPlXbYecNIba6Mrv8E6A__&Key-Pair-Id=APKAIE5G5CRDK6RD3PGA"
unzip $raw_root'/response.zip' -d $raw_root

python ./TCGA_dependencies/download_TCGA.py
python ./TCGA_dependencies/process_TCGA.py


