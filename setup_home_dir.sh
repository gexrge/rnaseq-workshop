#!/bin/bash

# ---- Setup home directory ----
# Change directory to work and make directories
cd /jupyter/work
mkdir results

# Rename 'rnaseq-workshop' to better describe its contents 
mv -r rnaseq-workshop scripts

# Change directory to home and make directories
cd ~
mkdir -p raw_data processed resources

# Change directory to download raw data into the correct directory
cd ~/raw_data

# Download fastq data
wget "https://zenodo.org/records/24397398/files/SIM1_KO_R1.fastq.gz" \
    "https://zenodo.org/records/24397398/files/SIM1_KO_R2.fastq.gz" \
    "https://zenodo.org/records/24397398/files/SIM1_WT_R1.fastq.gz" \
    "https://zenodo.org/records/24397398/files/SIM1_WT_R2.fastq.gz"

# Download genome (.fa) and annotation (.gtf) to resources
cd ~/resources
wget "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr6.fa.gz" \
    "https://hgdownload-test.gi.ucsc.edu/goldenPath/hg38/bigZips/genes/hg38.ncbiRefSeq.gtf.gz"
# should be: wget "https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/genes/hg38.ncbiRefSeq.gtf.gz"

# Decompress the downloaded genome and annotation (i.e. remove the .gz)
gunzip chr6.fa.gz hg38.ncbiRefSeq.gtf.gz

# Filter annotation for just chr6, which is specified in the 1st column
awk '$1 == "chr6"' hg38.ncbiRefSeq.gtf > hg38.ncbiRefSeq.chr6.gtf

