#!/bin/bash

#SBATCH --job-name=total_reads
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --output=data/logs/total_reads_%J.out
#SBATCH --error=data/logs/total_reads_%J.err

SAMPLES='data/metag_samples.txt'

## total reads merging SAGs and MarFERReT

while read SAMPLE
do
    
    echo ${SAMPLE}
    cat data/diamond/reads-vs-marferret/${SAMPLE}_100id_tax_lca.tsv data/diamond/reads-vs-sags/${SAMPLE}_100id_tax_lca.tsv | \
    grep -v qseqid | \
    awk '{print $1}' | \
    sort -u | \
    wc -l

done < ${SAMPLES} | paste - - > data/diamond/comparison_reads/sags_marferret_totals.tsv
