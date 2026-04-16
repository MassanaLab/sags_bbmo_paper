#!/bin/bash

#SBATCH --job-name=interproscan
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --output=data/logs/interproscan_%A_%a.out
#SBATCH --error=data/logs/interproscan_%A_%a.err
#SBATCH --array=1-147%8

SAG=$(awk "NR == ${SLURM_ARRAY_TASK_ID}" data/sags_list.txt)
INPUT=data/sags/${SAG}.aa
OUT_DIR=data/interproscan
INTERPROSCAN=~/smart/interproscan/interproscan-5.76-107.0/interproscan.sh

mkdir -p ${OUT_DIR}

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate
conda activate openjdk

## run interproscan

${INTERPROSCAN} \
  -i ${INPUT} \
  -f tsv \
  --cpu ${SLURM_CPUS_PER_TASK} \
  --goterms \
  --applications Pfam \
  --verbose \
  --output-file-base ${OUT_DIR}/${SAG}
