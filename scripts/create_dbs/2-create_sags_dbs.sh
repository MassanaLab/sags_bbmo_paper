#!/bin/bash

#SBATCH --job-name=create_sags_db
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --output=data/logs/create_sags_db_%J.out
#SBATCH --error=data/logs/create_sags_db_%J.err

module load diamond
module load salmon
module load seqkit

DATA_DIR='data/sags/'
OUT_DIR='data/db/'
OUT_NAME='sags_147'
SAGS_LIST='data/sags_list.txt'

mkdir -p ${OUT_DIR}

## aminoacids

while read SAG
do
    cat ${DATA_DIR}/${SAG}.aa
done < ${SAGS_LIST} \
> ${OUT_DIR}/${OUT_NAME}.aa

diamond makedb \
  --in ${OUT_DIR}/${OUT_NAME}.aa.gz \
  --db ${OUT_DIR}/${OUT_NAME}_aa

## salmon

### concatenate genomes and get decoys

while read SAG
do
    cat ${DATA_DIR}/${SAG}_scaffolds.fasta
done < ${SAGS_LIST} \
> ${OUT_DIR}/${OUT_NAME}_genomes.fasta

seqkit fx2tab -n "${OUT_DIR}/${OUT_NAME}_genomes.fasta" > "${OUT_DIR}/${OUT_NAME}_decoys.txt"

### concatenate CDS

while read SAG
do
    cat ${DATA_DIR}/${SAG}.cds
done < ${SAGS_LIST} \
> ${OUT_DIR}/${OUT_NAME}.cds

### combine CDS and Genome
cat "${OUT_DIR}/${OUT_NAME}.cds" "${OUT_DIR}/${OUT_NAME}_genomes.fasta" > "${OUT_DIR}/${OUT_NAME}_genomes_and_cds.fasta"

### build index

salmon index \
  -t "${OUT_DIR}/${OUT_NAME}_genomes_and_cds.fasta" \
  -d "${OUT_DIR}/${OUT_NAME}_decoys.txt" \
  -p "${SLURM_CPUS_PER_TASK}" \
  -i "${OUT_DIR}/${OUT_NAME}_index"

## annotations

while read SAG
do
    cat ${DATA_DIR}/${SAG}_pfam.tsv
done < ${SAGS_LIST} \
> ${OUT_DIR}/${OUT_NAME}_pfam.tsv

## compress

pigz -p ${SLURM_CPUS_PER_TASK} ${OUT_DIR}/*fasta ${OUT_DIR}/*cds ${OUT_DIR}/*tsv ${OUT_DIR}/${OUT_NAME}.aa
