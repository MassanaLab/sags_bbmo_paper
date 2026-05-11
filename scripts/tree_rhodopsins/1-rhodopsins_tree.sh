#!/bin/bash

#SBATCH --job-name=rho_tree
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --output=data/logs/rho_tree_%J.out
#SBATCH --error=data/logs/rho_tree_%J.err

OUT_DIR=data/rhodopsins/
REF_FASTA='data/rhodopsins/apurs_new_all_selected_sequences.fasta'
MFT_FASTA='data/rhodopsins/mft_rhodopsins_filt.fasta'
OUT_NAME='sags_mft_pnas'
ANNOTATION='data/db/sags_147_pfam.tsv.gz'
RHODO_PFAM='PF01036'
SAGS_AA='data/db/sags_147.aa.gz'

mkdir -p ${OUT_DIR}

module load R/4.2.2
module load mafft
module load trimal
module load iqtree3

## Get rhodopsins from SAGs

zcat ${ANNOTATION} | \
  awk -v rhodo_pfam=${RHODO_PFAM} '$5 == rhodo_pfam' | \
  cut -f1,7-8 \
  > ${OUT_DIR}/sags_rhodo_genes.tsv

cut -f1 ${OUT_DIR}/sags_rhodo_genes.tsv | seqkit grep -w0 -f - ${SAGS_AA} > ${OUT_DIR}/sags_rhodo_genes.fasta

## Trim fasta to keep only rhodopsin domain

Rscript scripts/trim_rhodo_fasta.R ${OUT_DIR}/sags_rhodo_genes.tsv ${OUT_DIR}/sags_rhodo_genes.fasta

## create all fasta

cat ${REF_FASTA} ${MFT_FASTA} ${OUT_DIR}/sags_rhodo_genes_trimmed.fasta > ${OUT_DIR}/${OUT_NAME}.aa

## mafft (linsi)

mafft \
 --thread -1 \
 --localpair \
 --maxiterate 1000 \
 ${OUT_DIR}/${OUT_NAME}.aa \
 > ${OUT_DIR}/${OUT_NAME}.aln

## trimal (using same -gt value as PNAS paper)

trimal \
 -in ${OUT_DIR}/${OUT_NAME}.aln \
 -gt 0.5 \
 -out ${OUT_DIR}/${OUT_NAME}.trimal

 ## iqtree

iqtree3 \
 -bb 1000 \
 -s ${OUT_DIR}/${OUT_NAME}.trimal \
 -alrt 1000 \
 -nt auto \
 -pre ${OUT_DIR}/${OUT_NAME}