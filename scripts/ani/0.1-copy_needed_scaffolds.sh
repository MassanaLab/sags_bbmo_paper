#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

LIST_DIR="lists"
OUT_BASE="data/clean/scaffolds_needed"
ICM_BASE="/mnt/smart/scratch/emm2/guillem/final_genomes_guigo_test/"

total_listed=0
total_copied=0
total_missing=0

for listfile in "$LIST_DIR"/*_lists.txt; do
    [ -e "$listfile" ] || continue

    group=$(basename "$listfile" "_lists.txt")
    outdir="$OUT_BASE/${group}_scaffolds"

    rm -rf "$outdir"
    mkdir -p "$outdir"

    echo
    echo "Processing: $group"

    while IFS= read -r sample || [ -n "$sample" ]; do
        [ -n "$sample" ] || continue
        total_listed=$((total_listed + 1))

        src="$ICM_BASE/$sample/${sample}_filter3_scaffolds.fasta"

        if [ -f "$src" ]; then
            cp "$src" "$outdir/"
            total_copied=$((total_copied + 1))
            echo "  OK: $sample"
        else
            total_missing=$((total_missing + 1))
            echo "  MISSING: $sample"
            echo "    expected: $src"
        fi
    done < "$listfile"
done

echo
echo "========== COUNT CHECK =========="
echo "List total:    $total_listed"
echo "Copied total:  $total_copied"
echo "Missing total: $total_missing"

if [ "$total_listed" -eq "$total_copied" ]; then
    echo "OK: all listed samples were copied"
else
    echo "ERROR: some listed samples were not copied"
fi

echo
echo "========== CONTENT CHECK =========="

problem_report="scaffold_check_problems.txt"
: > "$problem_report"

problem_count=0

for listfile in "$LIST_DIR"/*_lists.txt; do
    [ -e "$listfile" ] || continue

    group=$(basename "$listfile" "_lists.txt")
    outdir="$OUT_BASE/${group}_scaffolds"

    expected=$(mktemp)
    found=$(mktemp)
    missing_tmp=$(mktemp)
    extra_tmp=$(mktemp)

    sort -u "$listfile" > "$expected"

    find "$outdir" -maxdepth 1 -type f -name "*_filter3_scaffolds.fasta" -printf "%f\n" 2>/dev/null \
        | sed 's/_filter3_scaffolds\.fasta$//' \
        | sort -u > "$found"

    comm -23 "$expected" "$found" > "$missing_tmp"
    comm -13 "$expected" "$found" > "$extra_tmp"

    missing_n=$(wc -l < "$missing_tmp")
    extra_n=$(wc -l < "$extra_tmp")

    echo
    echo "Checking: $group"

    if [ "$missing_n" -eq 0 ] && [ "$extra_n" -eq 0 ]; then
        echo "  OK: list contents match copied files"
    else
        echo "  ERROR: mismatch between list and copied files"
        problem_count=$((problem_count + 1))

        {
            echo "=================================================="
            echo "Folder: $group"
            echo "Output dir: $outdir"
            echo
            echo "--- Missing sample IDs ---"
            [ "$missing_n" -gt 0 ] && cat "$missing_tmp" || echo "(none)"
            echo
            echo "--- Extra sample IDs ---"
            [ "$extra_n" -gt 0 ] && cat "$extra_tmp" || echo "(none)"
            echo
            echo "--- Files currently present in folder ---"
            find "$outdir" -maxdepth 1 -type f -printf "%f\n" | sort
            echo
        } | tee -a "$problem_report"
    fi

    rm -f "$expected" "$found" "$missing_tmp" "$extra_tmp"
done

echo
echo "========== FINAL CHECK SUMMARY =========="
echo "Problematic folders: $problem_count"
echo "Detailed report: $problem_report"
