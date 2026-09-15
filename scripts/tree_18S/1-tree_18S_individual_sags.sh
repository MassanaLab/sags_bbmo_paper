#!/bin/bash

#SBATCH --account=emm2
#SBATCH --job-name=iqtree_18S
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=500GB
#SBATCH --partition=high
#SBATCH --output=data/logs/iqtree_18S_%J.out
#SBATCH --error=data/logs/iqtree_18S_%J.err

OUT_DIR=data/tree_18S/
BASENAME=${OUT_DIR}/input/sags_individual_and_refs_18S

source activate base
conda activate phylofisher

## concatenate

cat ${OUT_DIR}/refs/ccm_ncbi_and_pr2_clust99.fasta ${OUT_DIR}/refs/sags_18S_individual_268.fasta > ${BASENAME}.fasta

## align

mafft --thread ${SLURM_CPUS_PER_TASK} ${BASENAME}.fasta > ${BASENAME}.pir

## trim

trimal -gt 0.05 -in ${BASENAME}.pir -out ${BASENAME}_trimmed.pir

## iqtree (model computed in a previous run that used virtually the same alignment)

iqtree3 \
 -bb 1000 \
 -s ${BASENAME}_trimmed.pir \
 -alrt 1000 \
 -T AUTO \
 -pre ${BASENAME} \
 -m GTR+F+R5
