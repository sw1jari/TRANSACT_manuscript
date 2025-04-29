# -*- coding: utf-8 -*-
"""
@author: Soufiane Mourragui
with code from Tycho Bismeijer

2020/01/03

READ DOWNLOADED DATA

This script reads files downloaded from TCGA using GDC tool.
"""

import os
import gzip
import pandas as pd


def read_metadata(pth):
    return pd.read_csv(pth, sep='\t')


def read_one_methyl_file(s, raw_folder):
    methyl_columns = ['Chromosome', 'Start', 'End', 'Gene_Symbol', 'Gene_Type']
    if '-' not in s:
        return False
    
    files = os.listdir(raw_folder + s)
    files = [f for f in files if '.txt' in f]
    
    if len(files) > 1:
        print('PROBLEME: MORE THAN ONE FILE FOR %s'%(s))
        
    methyl_df = pd.read_csv(raw_folder + s + '/' + files[0],
                            sep='\t')
    
    data_df = methyl_df[methyl_df.columns[:2]]
    data_df.columns = ['REF', 'beta_values']
    data_df = data_df.set_index('REF').T
    
    methyl_carac_df = methyl_df[methyl_df.columns[2:]]
    
    for c in methyl_columns:
        if c not in methyl_carac_df.columns:
            return s, data_df, methyl_carac_df
    return s, data_df, methyl_carac_df[methyl_columns]

def read_one_rnaseq_file(s, raw_folder):
    import os, pandas as pd

    # skip any entries that aren’t sample folders
    if '-' not in s:
        return False

    sample_dir = os.path.join(raw_folder, s)
    if not os.path.isdir(sample_dir):
        # nothing to read here
        return False

    # look for any .gz files in the sample folder
    gz_files = [f for f in os.listdir(sample_dir) if f.endswith('.gz')]
    if not gz_files:
        print(f"[!] No .gz files found for sample {s} in {sample_dir}")
        return False

    # prefer ones with “htseq” or “count” in the name, else just take the first .gz
    candidates = [f for f in gz_files if ('htseq' in f.lower() or 'count' in f.lower())]
    counts_file = candidates[0] if candidates else gz_files[0]
    counts_path = os.path.join(sample_dir, counts_file)

    try:
        df = pd.read_csv(
            counts_path,
            compression='gzip',
            sep='\t',
            header=None,
            names=['gene', 'count']
        )
    except Exception as e:
        print(f"[!] Error reading {counts_path}: {e}")
        return False

    # keep only Ensembl IDs (or adjust your regex as needed)
    df = df[df['gene'].str.contains('ENSG', na=False)]
    return s, df, pd.DataFrame()

def read_one_miRNA_file(s, raw_folder):
    if '-' not in s:
        return s, pd.DataFrame(), pd.DataFrame()
        
    f = os.listdir(raw_folder + s)
    f = [e for e in f if 'quantification' in e][0]
    return s, pd.read_csv('%s%s/%s'%(raw_folder, s, f), sep='\t'), pd.DataFrame()