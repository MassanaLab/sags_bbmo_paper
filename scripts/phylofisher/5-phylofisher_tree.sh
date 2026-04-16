#!/bin/bash

#SBATCH --job-name=iqtree
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --output=data/logs/iqtree_%J.out
#SBATCH --error=data/logs/iqtree_%J.err

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate base
conda activate phylofisher

PHYLOFISHER_DIR='data/phylofisher/'
OUT_DIR=${PHYLOFISHER_DIR}/final_tree
mkdir -p ${OUT_DIR}
OUT_NAME=${OUT_DIR}/PF.SAGs

## 1. Generate a LG+C20+F+G ML tree from the super-matrix

iqtree3 \
  -T ${SLURM_CPUS_PER_TASK} \
  -m LG+C20+F+G \
  -s ${PHYLOFISHER_DIR}/matrix_constructor_out_*/matrix.fas \
  -pre ${OUT_NAME}.LGC20GF \
  -mem 1000G

## 2. Use the LG+C20+F+G ML tree from the super-matrix as a guide tree for LG+C60+F+G+PMSF to generate an ML tree and a site frequencies file (.sitefreq)

iqtree3 \
  -T ${SLURM_CPUS_PER_TASK} \
  -ft ${OUT_NAME}.LGC20GF.treefile \
  -m LG+C60+F+G \
  -s ${PHYLOFISHER_DIR}/matrix_constructor_out_*/matrix.fas \
  -pre ${OUT_NAME}.LGC60GCF-PMSF \
  -mem 1000G \
  -alrt 1000 \
  -bb 1000
