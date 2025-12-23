#!/bin/bash
# Database Setup Script

PROJECT_DIR=$(pwd)
DB_DIR="$PROJECT_DIR/databases"
mkdir -p $DB_DIR/host_genome $DB_DIR/kraken2_db $DB_DIR/genomad_db $DB_DIR/checkm_db $DB_DIR/amr_db

source $(conda info --base)/etc/profile.d/conda.sh

# 1. Host Genome
echo "Downloading Host Genome..."
wget -c -P $DB_DIR/host_genome/ https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
gunzip $DB_DIR/host_genome/*.gz
mv $DB_DIR/host_genome/*.fna $DB_DIR/host_genome/host.fasta

# 2. geNomad Database
echo "Downloading geNomad Database..."
conda activate phage_env
genomad download-database $DB_DIR/genomad_db
conda deactivate

# 3. CheckM Database
echo "Downloading CheckM Database..."
wget -c -P $DB_DIR/checkm_db/ https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xvzf $DB_DIR/checkm_db/checkm_data_2015_01_16.tar.gz -C $DB_DIR/checkm_db/
conda activate checkm_env
checkm data setroot $DB_DIR/checkm_db
conda deactivate

# 4. AMRFinderPlus Database
echo "Downloading AMRFinderPlus Database..."
conda activate amr_env
amrfinder -u
conda deactivate

echo "Databases ready."
