#!/bin/bash

#SBATCH --job-name=length_filter
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --output=data/logs/length_filter_%A_%a.out
#SBATCH --error=data/logs/length_filter_%A_%a.err
#SBATCH --array=1-21%10

module load cutadapt
module load seqkit

# download metaT from here: https://doi.org/10.5281/zenodo.18922885

SAMPLE=$(awk "NR == ${SLURM_ARRAY_TASK_ID}" data/metat/metat_samples.txt)
DATA_DIR="data/metat/metaT.clean.reads/"
OUT_DIR="data/metat/"
FORWARD=${DATA_DIR}/${SAMPLE}_R1.clean.fastq.gz
REVERSE=${DATA_DIR}/${SAMPLE}_R2.clean.fastq.gz
MIN_LENGTH=135

FORWARD_OUT=${OUT_DIR}/${SAMPLE}_min${MIN_LENGTH}_R1.fastq.gz
REVERSE_OUT=${OUT_DIR}/${SAMPLE}_min${MIN_LENGTH}_R2.fastq.gz

mkdir -p ${OUT_DIR}

## paired-end files

cutadapt \
  --pair-filter=any \
  --minimum-length=${MIN_LENGTH} \
  -o ${FORWARD_OUT} \
  -p ${REVERSE_OUT} \
  ${FORWARD} \
  ${REVERSE}
