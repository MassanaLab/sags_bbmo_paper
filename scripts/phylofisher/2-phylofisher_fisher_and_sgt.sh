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

# I modified the SGT part to go faster with more parallelization

PHYLOFISHER_DIR='data/phylofisher/'
cd ${PHYLOFISHER_DIR}

## Homolog collection
fisher.py --threads ${SLURM_CPUS_PER_TASK}

## Produce preliminary statistics about newly input data.
informant.py --input fisher_out_*

## Collect taxa, and homologs for gene tree construction
working_dataset_constructor.py --input fisher_out_*

## Construct gene trees
sgt_constructor_AO.py --input working_dataset_constructor_out_* --threads ${SLURM_CPUS_PER_TASK}

## Render .svg and .tsv files of gene trees for visualization with ParaSorter
forest.py --input sgt_constructor_out_* --threads ${SLURM_CPUS_PER_TASK}
