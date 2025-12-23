# Shotgun Metagenomics Analysis Pipeline  
**Host-filtered Assembly, Binning, Phage Detection, MAG QC & AMR Profiling**

A modular, Conda-based **shotgun metagenomics pipeline** for paired-end Illumina data, covering the full workflow from raw reads to **high-quality metagenome-assembled genomes (MAGs)**, **phage discovery**, and **antimicrobial resistance (AMR) gene detection**.

---

## Key Features

- ✔ Automated **environment isolation** using Conda
- ✔ Adapter trimming & quality control
- ✔ **Host genome subtraction**
- ✔ De novo assembly with **MEGAHIT**
- ✔ **Phage identification** using geNomad
- ✔ Genome binning (MaxBin2)
- ✔ MAG quality assessment (CheckM)
- ✔ **AMR gene detection** (AMRFinderPlus)
- ✔ Integrated **MultiQC reporting**
- ✔ Scalable for multiple samples

---

## Pipeline Overview

```

Raw FASTQ
│
├── Fastp (QC + trimming)
│
├── BWA Host Decontamination
│
├── MEGAHIT Assembly
│
├── geNomad (Phage detection)
│
├── Binning (MaxBin2)
│
├── CheckM (MAG quality)
│
├── AMRFinderPlus (AMR genes)
│
└── MultiQC Summary

```

---

## Directory Structure

```

project/
├── raw_reads/
│   ├── sample1_1.fastq.gz
│   ├── sample1_2.fastq.gz
│
├── databases/
│   ├── host_genome/host.fasta
│   └── genomad_db/genomad_db/
│
├── results/
│   ├── clean_reads/
│   ├── non_host_reads/
│   ├── assembly/
│   ├── phage/
│   ├── bins/
│   ├── amr/
│   └── multiqc_report/
│
├── setup_envs.sh
├── run_pipeline.sh
└── README.md

```

---

## Requirements

### System
- Linux (Ubuntu recommended)
- ≥ 16 CPU threads
- ≥ 64 GB RAM recommended
- Conda / Miniconda installed

### Input Data
- Paired-end FASTQ files named as:
```

sampleID_1.fastq.gz
sampleID_2.fastq.gz

````

---

## Conda Environments

The pipeline uses **separate Conda environments per tool** for stability and reproducibility.

| Environment | Tools |
|------------|------|
| `fastqc_env` | FastQC |
| `trim_env` | fastp |
| `bwa_samtools_env` | BWA, Samtools |
| `assemble_env` | MEGAHIT |
| `phage_env` | geNomad |
| `binning_env` | MaxBin2, MetaBAT2 |
| `checkm_env` | CheckM |
| `amr_env` | AMRFinderPlus |
| `multiqc_env` | MultiQC |

---

## Installation

### Create Conda Environments

```bash
bash setup_envs.sh
````

This will automatically install all required tools.

---

## Database Setup

### Host Genome (Mandatory)

Place the host reference genome:

```
databases/host_genome/host.fasta
```

> Example: Human (GRCh38), Mouse, Plant host, etc.

---

### geNomad Database

Download and place the geNomad database:

```
databases/genomad_db/genomad_db/
```

Ensure the directory name is exactly `genomad_db`.

---

## Running the Pipeline

```bash
bash run_pipeline.sh
```

The pipeline automatically detects all samples in `raw_reads/`.

---

## Description

### Read Trimming (fastp)

* Adapter detection
* Quality filtering (Q ≥ 20)
* Multi-threaded
* Output: cleaned paired reads

---

### Host Decontamination (BWA + Samtools)

* Reads aligned to host genome
* Properly paired **unmapped reads extracted**
* Output: host-free metagenomic reads

---

### Assembly (MEGAHIT)

* De novo metagenomic assembly
* Optimized for large datasets
* Output:

  ```
  sample_contigs.fasta
  ```

---

### Phage Identification (geNomad)

* End-to-end viral and plasmid detection
* Neural network + HMM-based classification
* Outputs:

  * Phage contigs
  * Viral taxonomy
  * Annotation files

---

### Genome Binning (MaxBin2)

* Coverage-based binning
* BAM-derived depth calculation
* Outputs:

  ```
  sample_bin.001.fasta
  sample_bin.002.fasta
  ```

---

### MAG Quality Control (CheckM)

* Lineage-specific marker analysis
* Reports:

  * Completeness
  * Contamination
  * Strain heterogeneity

**High-quality MAG criteria (recommended):**

* Completeness ≥ 90%
* Contamination ≤ 5%

---

### AMR Gene Detection (AMRFinderPlus)

* Searches bins for:

  * AMR genes
  * Stress response genes
  * Virulence-associated resistance
* Output: per-bin AMR reports

---

### Global Reporting (MultiQC)

Aggregates:

* fastp
* assembly stats
* CheckM
* AMRFinderPlus

Output:

```
results/multiqc_report/
```

---

## Output Summary

| Analysis       | Output                      |
| -------------- | --------------------------- |
| Clean Reads    | `clean_reads/*.fastq.gz`    |
| Non-host Reads | `non_host_reads/*.fastq.gz` |
| Assemblies     | `assembly/*_contigs.fasta`  |
| Phages         | `phage/*`                   |
| MAGs           | `bins/*_bins/*.fasta`       |
| MAG QC         | `bins/*_checkm/*.txt`       |
| AMR Genes      | `amr/*/*.txt`               |
| Summary        | `multiqc_report/`           |

---

## Best Practices

* Use **co-assembly** for low biomass samples
* Filter short contigs (<1 kb) before binning if needed
* Consider combining **MetaBAT2 + MaxBin2** for ensemble binning
* Validate AMR results using phenotype if clinical

---

## Reproducibility

* Fully Conda-isolated
* Deterministic tool versions
* Modular and auditable

---

## Citation

If used in research, please cite:

* MEGAHIT
* geNomad
* MaxBin2
* CheckM
* AMRFinderPlus

(Official citations available in respective tool documentation)

---

## Developer

**Neloy Kumar Mazumder**  
Core Research Manager  
*Dawn of Bioinformatics Ltd.*

---



