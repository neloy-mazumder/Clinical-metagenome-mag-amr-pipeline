#!/bin/bash
# Main Metagenomics Execution Script (Updated with CheckM & AMRFinderPlus)

# --- CONFIGURATION ---
PROJECT_DIR=$(pwd)
THREADS=16  
RAW_DIR="$PROJECT_DIR/raw_reads"
RESULTS_DIR="$PROJECT_DIR/results"
DB_DIR="$PROJECT_DIR/databases"

HOST_REF="$DB_DIR/host_genome/host.fasta"
GENOMAD_DB=$(find $DB_DIR/genomad_db -name "genomad_db" -type d | head -n 1)

source $(conda info --base)/etc/profile.d/conda.sh
mkdir -p $RESULTS_DIR/fastqc $RESULTS_DIR/clean_reads $RESULTS_DIR/non_host_reads \
         $RESULTS_DIR/assembly $RESULTS_DIR/phage $RESULTS_DIR/bins $RESULTS_DIR/amr

# Index Host
if [ ! -f "${HOST_REF}.bwt" ]; then
    conda activate bwa_samtools_env
    bwa index $HOST_REF
    conda deactivate
fi

SAMPLES=$(ls $RAW_DIR/*_1.fastq.gz | xargs -n 1 basename | sed 's/_1.fastq.gz//')

for SAMPLE in $SAMPLES; do
    echo "Processing: $SAMPLE"

    # 1. Trimming
    conda activate trim_env
    fastp -i $RAW_DIR/${SAMPLE}_1.fastq.gz -I $RAW_DIR/${SAMPLE}_2.fastq.gz \
          -o $RESULTS_DIR/clean_reads/${SAMPLE}_trim_1.fastq.gz -O $RESULTS_DIR/clean_reads/${SAMPLE}_trim_2.fastq.gz \
          -q 20 -w $THREADS --detect_adapter_for_pe
    conda deactivate

    # 2. Host Subtraction
    conda activate bwa_samtools_env
    bwa mem -t $THREADS $HOST_REF $RESULTS_DIR/clean_reads/${SAMPLE}_trim_1.fastq.gz $RESULTS_DIR/clean_reads/${SAMPLE}_trim_2.fastq.gz | \
    samtools view -b -f 12 -F 256 | samtools sort -n -@ $THREADS -o $RESULTS_DIR/non_host_reads/${SAMPLE}_unmapped.bam
    samtools fastq -@ $THREADS -1 $RESULTS_DIR/non_host_reads/${SAMPLE}_nonhost_1.fastq.gz -2 $RESULTS_DIR/non_host_reads/${SAMPLE}_nonhost_2.fastq.gz -n $RESULTS_DIR/non_host_reads/${SAMPLE}_unmapped.bam
    conda deactivate

    # 3. Assembly (MEGAHIT)
    conda activate assemble_env
    megahit -1 $RESULTS_DIR/non_host_reads/${SAMPLE}_nonhost_1.fastq.gz -2 $RESULTS_DIR/non_host_reads/${SAMPLE}_nonhost_2.fastq.gz -o $RESULTS_DIR/assembly/${SAMPLE}_megahit -t $THREADS
    cp $RESULTS_DIR/assembly/${SAMPLE}_megahit/final.contigs.fa $RESULTS_DIR/assembly/${SAMPLE}_contigs.fasta
    conda deactivate

    # 4. Phage Identification (geNomad)
    conda activate phage_env
    genomad end-to-end --cleanup --threads $THREADS $RESULTS_DIR/assembly/${SAMPLE}_contigs.fasta $RESULTS_DIR/phage/${SAMPLE}_out $GENOMAD_DB
    conda deactivate

    # 5. Binning (MaxBin2)
    conda activate bwa_samtools_env
    bwa index $RESULTS_DIR/assembly/${SAMPLE}_contigs.fasta
    bwa mem -t $THREADS $RESULTS_DIR/assembly/${SAMPLE}_contigs.fasta $RESULTS_DIR/non_host_reads/${SAMPLE}_nonhost_1.fastq.gz $RESULTS_DIR/non_host_reads/${SAMPLE}_nonhost_2.fastq.gz | samtools sort -@ $THREADS -o $RESULTS_DIR/assembly/${SAMPLE}_mapped.bam
    conda deactivate

    conda activate binning_env
    mkdir -p $RESULTS_DIR/bins/${SAMPLE}_bins
    jgi_summarize_bam_contig_depths --outputDepth $RESULTS_DIR/bins/${SAMPLE}_depth.txt $RESULTS_DIR/assembly/${SAMPLE}_mapped.bam
    run_MaxBin.pl -contig $RESULTS_DIR/assembly/${SAMPLE}_contigs.fasta -abund $RESULTS_DIR/bins/${SAMPLE}_depth.txt -out $RESULTS_DIR/bins/${SAMPLE}_bins/${SAMPLE}_bin -thread $THREADS
    conda deactivate

    # 6. CheckM Quality Control
    conda activate checkm_env
    mkdir -p $RESULTS_DIR/bins/${SAMPLE}_checkm
    checkm lineage_wf -t $THREADS -x fasta --reduced_tree $RESULTS_DIR/bins/${SAMPLE}_bins/ $RESULTS_DIR/bins/${SAMPLE}_checkm/
    checkm qa $RESULTS_DIR/bins/${SAMPLE}_checkm/lineage.ms $RESULTS_DIR/bins/${SAMPLE}_checkm/ -f $RESULTS_DIR/bins/${SAMPLE}_checkm_report.txt --tab_table -o 2
    conda deactivate

    # 7. AMR Gene Identification (AMRFinderPlus)
    
    echo ">>>> Running AMRFinderPlus on Bins for $SAMPLE <<<<"
    conda activate amr_env
    mkdir -p $RESULTS_DIR/amr/${SAMPLE}_amr_results
    for BIN in $RESULTS_DIR/bins/${SAMPLE}_bins/*.fasta; do
        BIN_NAME=$(basename $BIN .fasta)
        amrfinder -n $BIN --threads $THREADS > $RESULTS_DIR/amr/${SAMPLE}_amr_results/${BIN_NAME}_amr.txt
    done
    conda deactivate

done

# 8. Final MultiQC
conda activate multiqc_env
multiqc $RESULTS_DIR/ -o $RESULTS_DIR/multiqc_report
conda deactivate

echo "Pipeline Finished Successfully!"
