#!/bin/bash

#SBATCH --job-name=phylofisher_config
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --output=data/logs/phylofisher_config_%J.out
#SBATCH --error=data/logs/phylofisher_config_%J.err

export PATH=/home/aobiol/smart/miniforge3/bin/:${PATH}
source activate base
conda activate phylofisher

PHYLOFISHER_DIR='data/phylofisher/'
cd ${PHYLOFISHER_DIR}

INPUT_METADATA='input_metadata.tsv'
DATABASE='db/PhyloFisherDatabase_v1.0/database/'

## Create and set up the PhyloFisher configuration file
config.py -d ${DATABASE} -i ${INPUT_METADATA}
