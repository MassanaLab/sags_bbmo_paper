#!/bin/bash

#SBATCH --job-name=length_filter
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --output=data/logs/length_filter_%A_%a.out
#SBATCH --error=data/logs/length_filter_%A_%a.err
#SBATCH --array=1-32%10

module load cutadapt
module load seqkit

SAMPLE=$(cat data/metag_samples.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}")
DATA_DIR="data/metag"
FORWARD=${DATA_DIR}/${SAMPLE}_R1.clean.fastq.gz
REVERSE=${DATA_DIR}/${SAMPLE}_R2.clean.fastq.gz
MIN_LENGTH=135
FORWARD_OUT=${DATA_DIR}/${SAMPLE}_min${MIN_LENGTH}_R1.fastq.gz
REVERSE_OUT=${DATA_DIR}/${SAMPLE}_min${MIN_LENGTH}_R2.fastq.gz

## paired-end files

cutadapt \
  --pair-filter=any \
  --minimum-length=${MIN_LENGTH} \
  -o ${FORWARD_OUT} \
  -p ${REVERSE_OUT} \
  ${FORWARD} \
  ${REVERSE}

## concatenate

OUT_DIR="${DATA_DIR}/for_mapping/"

mkdir -p ${OUT_DIR}

./scripts/fastq-interleave \
  ${FORWARD_OUT} \
  ${REVERSE_OUT} | \
seqkit fq2fa \
 -o ${OUT_DIR}/${SAMPLE}.fasta

pigz -p ${SLURM_CPUS_PER_TASK} ${OUT_DIR}/${SAMPLE}.fasta

## stats

seqkit stats -abT \
  ${OUT_DIR}/${SAMPLE}.fasta.gz > ${OUT_DIR}/${SAMPLE}_stats.tsv

## remove intermediate files

rm ${FORWARD_OUT} ${REVERSE_OUT}
