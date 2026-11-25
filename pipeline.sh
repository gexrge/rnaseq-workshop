#!/bin/bash

set -euo pipefail

# Reinstate conda if lost (i.e. (base)...)
source ~/miniconda3/etc/profile.d/conda.sh

# Activate the conda environment containing our apps/tools
conda activate rnaseq

# ---- Step 1: fastqc ----
# Change directory to processed and make a directory for the output of our 1st step - fastqc
cd ~/processed
mkdir -p 1_fastqc

# Change directory to where our input data is kept
cd ~/raw_data

# Run fastqc on all fastq files in the current directory
# '--outdir' specifies where to send the output of fastqc
# '--threads' specifies the number of workers we have available
fastqc *.fastq.gz --outdir ~/processed/1_fastqc --threads 8

# ---- Step 2: MultiQC ----
# Change directory to processed and make a directory for the output of our 2nd step - multiqc
cd ~/processed
mkdir -p 2_multiqc

# Run multiqc on the output of fastqc to make a combined report
# '--outdir' specifies where to send the output of multiqc
multiqc 1_fastqc --outdir 2_multiqc

# Lets take a look at our QC! 

# Zip (i.e. compress) multiqc output so we can download it from vLab
zip -r 2_multiqc.zip 2_multiqc/

# Move the zip file to the work directory where we can download from
mv 2_multiqc.zip /jupyter/work/results/

# ---- Step 3: Alignment ---- 
# Change directory to resources and make a directory for the output of our genome index
cd ~/resources
mkdir -p hisat2_index

# Build an index for our genome to create a "map" to make it easier and faster to navigate for hisat2
# '-p' specifies the number of workers we have available
# '--quiet' specifies that we don't want unncessary printing from hisat2-build
hisat2-build -p 8 --quiet chr6.fa hisat2_index/hisat2_index

# Change directory to processed and make a directory for the ouput of our 3rd step - Alignment
cd ~/processed
mkdir -p 3_hisat2

# Change directory to where our input data for hisat2 is kept
cd ~/raw_data

# Run hisat2 to align the SIM1 WT transcripts to our indexed genome
# '-x' specifies where the indexed genome is and what the suffix is
# '-1' specifies where the forward strand reads are
# '-2' specifies where the reverse strand reads are
# '--threads' specifies the number of workers we have available
# '--sumary-file' specifies where to save a copy of the alignment report
# Run samtools sort on the output of hisat2 to compress output
# '--threads' specifies the number of workers we have available
# '-o' specifies where to send the output of samtools sort
hisat2 \
    -x ../resources/hisat2_index/hisat2_index \
    -1 SIM1_WT_R1.fastq.gz \
    -2 SIM1_WT_R2.fastq.gz \
    --threads 8 \
    --summary-file ../processed/3_hisat2/SIM1_WT_hisat2.log \
| samtools sort --threads 8 -o ../processed/3_hisat2/SIM1_WT_sorted.bam

# The same as before, but for SIM1 KO
hisat2 \
    -x ../resources/hisat2_index/hisat2_index \
    -1 SIM1_KO_R1.fastq.gz \
    -2 SIM1_KO_R2.fastq.gz \
    --threads 8 \
    --summary-file ../processed/3_hisat2/SIM1_KO_hisat2.log \
| samtools sort --threads 8 -o ../processed/3_hisat2/SIM1_KO_sorted.bam

# Change directory to where our bam (i.e. aligment) files are
cd ~/processed/3_hisat2

# Run samtools index to create a "map" for all bam files
# '--threads' specifies the number of works available
# '-M' specifies we want to index multiple bam files
samtools index --threads 8 -M *.bam

# ---- Step 4: MultiQC ----
# Change directory to processed and make a directory for the ouput of our 4th step - multiqc
cd ~/processed
mkdir -p 4_multiqc

# Run multiqc on our alignment reports (i.e. log files) to make a combined report
# '--outdir' specifies where to send the output of multiqc
multiqc 3_hisat2 --outdir 4_multiqc

# Let's take a look at our QC!
# Don't forget, we have to zip and move the output to download it
zip -r 4_multiqc.zip 4_multiqc/
mv 4_multiqc.zip /jupyter/work/results

# ---- Step 5: deeptools ----
# Change directory to processed and make a directory for the output of our 5th step - deeptools
cd ~/processed
mkdir -p 5_bigwig

# Change directory to where our input data for deeptools is kept
cd ~/processed/3_hisat2

# Run bamCoverage on our alignments (i.e. bam) to generate coverage tracks for WT and KO
# '--bam' specifies the input data
# '--outFileName' specifies the name and location of the output file
# '--normalizeUsing' specifies what normalisation method in order to standardise read depth
# '--numberOfProcessors' specifies the number of workers we have available
bamCoverage \
    --bam SIM1_WT_sorted.bam \
    --outFileName ../5_bigwig/SIM1_WT_cpm.bw \
    --normalizeUsing CPM \
    --numberOfProcessors 8

# Do the same again for KO
bamCoverage \
    --bam SIM1_KO_sorted.bam \
    --outFileName ../5_bigwig/SIM1_KO_cpm.bw \
    --normalizeUsing CPM \
    --numberOfProcessors 8
    
# Lets visualise the alignments in IGV!

# Change directory to processed where our output directories are saved
cd ~/processed

# Don't forget to zip and move them to the work directory
zip -r 5_bigwig.zip 5_bigwig/
mv 5_bigwig.zip /jupyter/work/results

# ---- Step 6: htseq ----
# Change directory to processed and make a directory for the ouput of our 6th step - htseq
cd ~/processed
mkdir -p 6_htseq

# Change directory to where our input data for htseq is kept
cd ~/processed/3_hisat2

# Run htseq-count on our alignments (i.e. bam) to count the number of reads per gene
# '--nprocesses' specifies the number of workers available to use
# '--stranded' specifies if library prep preserved information about which strand the RNA transcript came from
# '--order' specifies how the alignments are sorted (i.e. by position)
htseq-count \
    --nprocesses 8 \
    --stranded no \
    --order pos \
    SIM1_WT_sorted.bam \
    ~/resources/hg38.ncbiRefSeq.chr6.gtf \
    > ../6_htseq/SIM1_WT_counts.htseq

# Do the same for SIM1 KO data
htseq-count \
    --nprocesses 8 \
    --stranded no \
    --order pos \
    SIM1_KO_sorted.bam \
    ~/resources/hg38.ncbiRefSeq.chr6.gtf \
    > ../6_htseq/SIM1_KO_counts.htseq

# Lets make a combined count matrix!

# Change directory to where our counts are
cd ~/processed/6_htseq

# Print/echo our matrix headers into an empty file to populate
echo -e "gene\tSIM1_WT\tSIM1_KO" > SIM1_merged_counts.tsv

# Paste together select columns from both count files and send to empty file with headers
paste \
    <(cut -f1 SIM1_WT_counts.htseq) \
    <(cut -f2 SIM1_WT_counts.htseq) \
    <(cut -f2 SIM1_KO_counts.htseq) \
    >> SIM1_merged_counts.tsv
    
# Copy merged count matrix to work to be saved
cp SIM1_merged_counts.tsv /jupyter/work/results