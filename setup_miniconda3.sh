#!/bin/bash

# ---- Setup tools ----
# Change directory to work and download conda setup script
cd ~
wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

# Install conda
bash Miniconda3-latest-Linux-x86_64.sh

# Invoke conda (you will see '(base)' at the beginning of your prompt (i.e. before the $))
source ~/.bashrc

# If you crash and need to reinvoke conda, run this vvv
# source /jupyter/work/miniconda3/etc/profile.d/conda.sh

# Check conda is set up (if it is, the following command will print your conda version)
conda --version

# Clean up
rm Miniconda3-latest-Linux-x86_64.sh

# Add channels to tell conda where to install tools from
conda config -q --add channels conda-forge
conda config -q --add channels bioconda
conda config -q --add channels defaults

# Install software using conda in an environment called 'rnaseq'
conda create -n rnaseq \
    fastqc \
    multiqc \
    hisat2 \
    samtools ncurses \
    deeptools \
    htseq \
    python=3.11

# Activate environment
conda activate rnaseq
