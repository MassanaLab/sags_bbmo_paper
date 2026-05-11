#!/bin/bash

#SBATCH --job-name=process_salmon
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --output=data/logs/process_salmon_%J.out
#SBATCH --error=data/logs/process_salmon_%J.err

module load R/4.2.2
Rscript scripts/merge_salmon.R