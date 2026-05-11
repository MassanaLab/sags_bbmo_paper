#!/bin/bash

#SBATCH --job-name=process_metag_recruitment
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --output=data/logs/process_metag_recruitment_%J.out
#SBATCH --error=data/logs/process_metag_recruitment_%J.err

SAMPLES='data/metag/metag_samples.txt'
mkdir -p data/diamond/comparison_reads

module load R/4.2.2

# Create OTU tab for SAGs and MarFERReT

for DB in sags marferret
do
    Rscript scripts/create_otutab.R ${DB}
done

# Mapped reads.

for DB in sags marferret
do
    while read SAMPLE
    do
        echo ${SAMPLE}
        awk -F'\t' '{sum += $2} END {print sum}' data/diamond/reads-vs-${DB}/${SAMPLE}_100id_tax_summary.tsv; done < ${SAMPLES} | paste - - > data/diamond/reads-vs-${DB}/${DB}_100id_mapped_reads.tsv
done

# Overlap.

DB=marferret
while read SAMPLE
do
    echo ${SAMPLE}
    awk -F'\t' '{sum += $3} END {print sum}' data/diamond/comparison_reads/${SAMPLE}_overlap_sags-vs-${DB}_100id.tsv
done < ${SAMPLES} | paste - - > data/diamond/comparison_reads/overlap_sags-vs-${DB}_100id.tsv

# No overlap.

for DB in sags marferret
do
    while read SAMPLE
    do
        echo ${SAMPLE}
        awk -F'\t' '{sum += $2} END {print sum}' data/diamond/comparison_reads/${SAMPLE}_no-overlap_sags-vs-marferret_100id_${DB}.tsv
    done < ${SAMPLES} | paste - - > data/diamond/comparison_reads/no-overlap_sags-vs-marferret_100id_${DB}.tsv
done

# total reads merging SAGs and MarFERReT

while read SAMPLE
do
    
    echo ${SAMPLE}
    cat data/diamond/reads-vs-marferret/${SAMPLE}_100id_tax_lca.tsv data/diamond/reads-vs-sags/${SAMPLE}_100id_tax_lca.tsv | \
    grep -v qseqid | \
    awk '{print $1}' | \
    sort -u | \
    wc -l

done < ${SAMPLES} | paste - - > data/diamond/comparison_reads/sags_marferret_totals.tsv

# Total metaG reads per sample.

cat data/metag/for_mapping/*stats.tsv | grep -v file | cut -f1,4 | perl -pe 's/\..*gz//' > data/metag/samples_metag_reads.tsv
