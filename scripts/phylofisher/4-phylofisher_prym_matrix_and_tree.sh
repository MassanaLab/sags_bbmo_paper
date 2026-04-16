#!/bin/bash

#SBATCH --job-name=phylofisher
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --output=data/logs/phylofisher_%J.out
#SBATCH --error=data/logs/phylofisher_%J.err

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate base
conda activate phylofisher

PHYLOFISHER_DIR='data/phylofisher/'
DATASET_DIR=prep_final_dataset_out_Feb.02.2026/prymnesiophyceae
OUT_DIR=prymnesiophyceae_tree
OUT_NAME=${OUT_DIR}/PF.prymnesiophyceae

cd ${PHYLOFISHER_DIR}

## matrix constructor

matrix_constructor_AO.py \
  --input ${DATASET_DIR} \
  --threads ${SLURM_CPUS_PER_TASK} \
  --output ${OUT_DIR}

## tree

### 1. Generate a LG+C20+F+G ML tree from the super-matrix

iqtree3 \
  -T ${SLURM_CPUS_PER_TASK} \
  -m LG+C20+F+G \
  -s ${OUT_DIR}/matrix.fas \
  -pre ${OUT_NAME}.LGC20GF

### 2. Use the LG+C20+F+G ML tree from the super-matrix as a guide tree for LG+C60+F+G+PMSF to generate an ML tree and a site frequencies file (.sitefreq)

iqtree3 \
  -T ${SLURM_CPUS_PER_TASK} \
  -ft ${OUT_NAME}.LGC20GF.treefile \
  -m LG+C60+F+G \
  -s ${OUT_DIR}/matrix.fas \
  -pre ${OUT_NAME}.LGC60GCF-PMSF \
  -alrt 1000 \
  -bb 1000
