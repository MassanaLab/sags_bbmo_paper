#!/bin/bash

#SBATCH --job-name=phylofisher
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --output=data/logs/phylofisher_%J.out
#SBATCH --error=data/logs/phylofisher_%J.err
#SBATCH --mem=1000GB

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate base
conda activate phylofisher

PHYLOFISHER_DIR='data/phylofisher/'
FOREST_DIR=${PHYLOFISHER_DIR}/forest_out_Feb.02.2026/

## I imported the forest dir created locally
## create symlinks to the tsv files renamed with the `parsed` suffix and proceed with next scripts

while read GENE
do 
    ln -s ${PWD}/${FOREST_DIR}/${GENE}.tsv ${FOREST_DIR}/${GENE}_parsed.tsv
done < data/phylofisher/genes_240.txt

cd ${PHYLOFISHER_DIR}

## apply to db

apply_to_db.py \
  -i forest_out_* \
  -fi fisher_out_* \
  --threads ${SLURM_CPUS_PER_TASK}

## prepare final dataset

prep_final_dataset.py

## matrix constructor

matrix_constructor_AO.py \
  --input prep_final_dataset_out_Feb.02.2026 \
  --output matrix_constructor_out_Feb.03.2026 \
  --threads ${SLURM_CPUS_PER_TASK}
