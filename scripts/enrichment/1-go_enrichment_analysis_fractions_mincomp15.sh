#!/bin/bash

#SBATCH --job-name=go_enrichment
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --output=data/logs/go_enrichment_%A_%a.out
#SBATCH --error=data/logs/go_enrichment_%A_%a.err
#SBATCH --array=1-119%80

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate base
conda activate R

MINCOMP=15

SAG=$(cat data/enrichment/enrichment_files/sags/sags_list_mincomp${MINCOMP}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}")
OUT_DIR='data/enrichment/result/go_terms/'
mkdir -p ${OUT_DIR}

FRACTION=$(awk -v var=${SAG} '{if ($1 == var){print $2}}' data/sags_fractions.tsv)

if [[ ${FRACTION} == "HF" ]]
then
    FRACTION_COMPARE="PF"
else
    FRACTION_COMPARE="HF"
fi

FRACTION_ANNOTATION="data/enrichment/enrichment_files/sags/${FRACTION_COMPARE}_sags_mincomp${MINCOMP}.rds"
SAG_ANNOTATION="data/enrichment/enrichment_files/sags/${SAG}.rds"
OUT_FILE=${OUT_DIR}/${SAG}-go_enrichment_vs_${FRACTION_COMPARE}-mincomp${MINCOMP}.tsv

Rscript scripts/topgo_enricher.R ${FRACTION_ANNOTATION} ${SAG_ANNOTATION} ${OUT_FILE}
