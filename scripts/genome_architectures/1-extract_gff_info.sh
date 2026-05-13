#!/usr/bin/env bash

#SBATCH --job-name=gff_info_braker
#SBATCH --output=data/logs/gff_info_braker_%A_%a.out
#SBATCH --error=data/logs/gff_info_braker_%A_%a.err
#SBATCH --array=1-4%4

set -euo pipefail

module load R/4.2.2

W="coass_revisit"

R_SCRIPT="scripts/Extract_gff_info_out_Braker.R"
NAMES_FILE="data/clean/names_${W}.txt"

GFF_DIR="/mnt/smart/scratch/emm2/guillem/coass_revisit2/data/clean/aleix_gff_process_big2_coass_revisit_filter3/final_gff3"
FA_DIR="/mnt/smart/scratch/emm2/guillem/coass_revisit2/data/clean/aleix_gff_process_big2_coass_revisit_filter3/assemblies3_clean"

OUT_DIR="data/clean/${W}_annotation_stats_test3"
LOG_DIR="data/logs/${W}"
SLURM_LOG_DIR="data/logs"

mkdir -p "$OUT_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$SLURM_LOG_DIR"

[[ -f "$R_SCRIPT" ]] || { echo "ERROR: R script not found: $R_SCRIPT" >&2; exit 1; }
[[ -f "$NAMES_FILE" ]] || { echo "ERROR: names file not found: $NAMES_FILE" >&2; exit 1; }
[[ -d "$GFF_DIR" ]] || { echo "ERROR: GFF directory not found: $GFF_DIR" >&2; exit 1; }
[[ -d "$FA_DIR" ]] || { echo "ERROR: FASTA directory not found: $FA_DIR" >&2; exit 1; }

SAMPLE="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$NAMES_FILE")"

if [[ -z "$SAMPLE" ]]; then
    echo "No SAMPLE found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
    exit 0
fi

gff="${GFF_DIR}/${SAMPLE}_filter3.gff3"
fa="${FA_DIR}/${SAMPLE}.fasta"
sample_outdir="${OUT_DIR}/${SAMPLE}"

echo "=== Processing: $SAMPLE ==="
echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
echo "GFF: $gff"
echo "FASTA: $fa"
echo "Output dir: $sample_outdir"

if [[ ! -f "$gff" ]]; then
    echo "WARNING: missing GFF, skipping: $gff" >&2
    exit 0
fi

if [[ ! -f "$fa" ]]; then
    echo "WARNING: missing FASTA, skipping: $fa" >&2
    exit 0
fi

mkdir -p "$sample_outdir"

cd "$sample_outdir"

Rscript "$OLDPWD/$R_SCRIPT" \
    "$SAMPLE" \
    "$gff" \
    "$fa" \
    > "$OLDPWD/$LOG_DIR/${SAMPLE}.stdout.log" \
    2> "$OLDPWD/$LOG_DIR/${SAMPLE}.stderr.log"

echo "Done: $SAMPLE"
