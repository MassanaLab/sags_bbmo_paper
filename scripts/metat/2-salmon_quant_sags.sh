#!/bin/bash

#SBATCH --job-name=salmon
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --output=data/logs/salmon_quant_%A_%a.out
#SBATCH --error=data/logs/salmon_quant_%A_%a.err
#SBATCH --array=1-21%4

#module load salmon

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate base
conda activate salmon

SAMPLE=$(awk "NR == ${SLURM_ARRAY_TASK_ID}" data/metat_samples.txt)
INDEX="data/db/sags_147_index/"
DATA_DIR='data/metat/'
FW_READS=${DATA_DIR}/${SAMPLE}_min135_R1.fastq.gz
RV_READS=${DATA_DIR}/${SAMPLE}_min135_R2.fastq.gz
OUT_DIR="data/salmon/${SAMPLE}"

mkdir -p ${OUT_DIR}

salmon \
quant \
  --index ${INDEX} \
  --libType A \
  -1 ${FW_READS} \
  -2 ${RV_READS} \
  --output ${OUT_DIR} \
  --threads ${SLURM_CPUS_PER_TASK}
