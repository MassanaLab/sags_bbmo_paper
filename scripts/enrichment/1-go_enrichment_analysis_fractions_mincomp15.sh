#!/bin/bash

#SBATCH --job-name=go_enrichment
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --output=data/logs/go_enrichment_%A_%a.out
#SBATCH --error=data/logs/go_enrichment_%A_%a.err
#SBATCH --array=1-119%80

module load R/4.2.2

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

## merge results like this with R:

# R
#enrichment_files_sags_sort_mincomp15 <-
#  list.files('data/enrichment/result/go_terms/', pattern = '-go_enrichment_vs_[HP]F-mincomp15.tsv', full.names = T) |>
#  purrr::map(~ read_tsv(.x) |>
#        mutate(sag_id  = str_remove(basename(.x),'-go_enrichment.*'),
#               enriched_in = if_else(str_match(.x, '.*_([HP]F)')[,2] == 'HF', 'PF','HF'))
#  ) |>
#  bind_rows()
#    
#enrichment_files_sags_sort_mincomp15 %>%
#    write_tsv('data/enrichment/result/sags-go_enrichment-sort_mincomp15.tsv')