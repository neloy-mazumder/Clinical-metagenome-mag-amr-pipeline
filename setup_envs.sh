#!/bin/bash
# Environment Setup for Metagenomics Pipeline

source $(conda info --base)/etc/profile.d/conda.sh

echo "Creating Conda environments..."

conda create -y -n fastqc_env -c bioconda fastqc
conda create -y -n trim_env -c bioconda fastp
conda create -y -n bwa_samtools_env -c bioconda bwa samtools
conda create -y -n assemble_env -c bioconda megahit
conda create -y -n kraken_env -c bioconda kraken2
conda create -y -n phage_env -c bioconda -c conda-forge genomad
conda create -y -n binning_env -c bioconda maxbin2 metabat2
conda create -y -n checkm_env -c bioconda checkm-genome
conda create -y -n amr_env -c bioconda ncbi-amrfinderplus
conda create -y -n multiqc_env -c bioconda multiqc

echo "All environments created successfully."
