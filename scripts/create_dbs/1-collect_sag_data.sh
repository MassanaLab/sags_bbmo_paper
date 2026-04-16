#!/bin/bash

#SBATCH --account=emm2
#SBATCH --job-name=sags_data
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --output=data/logs/sags_data_%A_%a.out
#SBATCH --error=data/logs/sags_data_%A_%a.err
#SBATCH --array=1-147%50

module load seqkit

SAG=$(awk "NR == ${SLURM_ARRAY_TASK_ID}" data/sags_list.txt)

BASENAME="/mnt/smart/scratch/emm2/02-PROCESSED_DATA/SAGs_curated/SAGs_FINAL_GENOMES/${SAG}/${SAG}"
GENOME=${BASENAME}_filter3_scaffolds.fasta
PROTEINS=${BASENAME}_filter3_genes.aa
CDS=${BASENAME}_filter3_genes.cds

OUT_DIR=data/sags/

for FILE in ${GENOME} ${PROTEINS} ${CDS}
do
    OUT_FILE=${OUT_DIR}/$(basename ${FILE/_filter3_genes/})
    seqkit replace -p '^' -r "${SAG}_" ${FILE} | seqkit replace -w0 -p ' .*' -r '' > ${OUT_FILE}
done

rename 'filter3_' '' ${OUT_DIR}/*
