#!/bin/bash

#SBATCH --job-name=diamond_reads-vs-sags
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --output=data/logs/diamond_reads-vs-sags_%A_%a.out
#SBATCH --error=data/logs/diamond_reads-vs-sags_%A_%a.err
#SBATCH --array=1-32%4

module load diamond
module load R/4.2.2

# Change

DB='data/db/sags_147_aa.dmnd'
DB_NAME=sags

## Script

SAMPLE=$(awk "NR == ${SLURM_ARRAY_TASK_ID}" data/metag_samples.txt)
QUERY=data/metag/for_mapping/${SAMPLE}.fasta.gz
OUT_DIR=data/diamond/reads-vs-${DB_NAME}
mkdir -p ${OUT_DIR}
OUT_FILE=${OUT_DIR}/${SAMPLE}_blastx.outfmt6

## Run DIAMOND

diamond \
  blastx \
  --query ${QUERY} \
  --db ${DB} \
  --threads ${SLURM_CPUS_PER_TASK} \
  --out ${OUT_FILE} \
  --outfmt 6 \
  --unal 0 \
  --fast

pigz -p ${SLURM_CPUS_PER_TASK} ${OUT_FILE}

## add taxonomy

ADD_TAXONOMY='Rscript scripts/add_taxonomy_reads.R'

### get filtered diamond file

zcat ${OUT_FILE}.gz | awk '$3 == 100' | awk '$4 >= 45' | cut -f1-4 > ${OUT_DIR}/${SAMPLE}_temp_filt

${ADD_TAXONOMY} ${OUT_DIR}/${SAMPLE}_temp_filt ${DB_NAME} ${OUT_DIR}/${SAMPLE}_100id_tax

rm ${OUT_DIR}/${SAMPLE}_temp_filt

## extract overlapping reads with marferret

OUT_DIR="data/diamond/comparison_reads/"
mkdir -p ${OUT_DIR}

OVERLAP_SCRIPT='Rscript scripts/overlap_reads.R'

${OVERLAP_SCRIPT} \
  marferret \
  ${SAMPLE}
