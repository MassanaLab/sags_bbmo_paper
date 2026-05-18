#!/usr/bin/env bash

# This script will look for the needed scaffolds files. This is very personal, personalize it yourself so you have one scaffolds
# folder for each tax, with all scaffolds file per sample inside.

set -euo pipefail
shopt -s nullglob

LIST_DIR="lists"
OUT_BASE="data/clean/scaffolds_needed"

# Always check this folder first
ICM_BASE="/mnt/smart/scratch/emm2/guillem/final_genomes_new_sags_dec_test"

# Alternative curated SAG folders
SAG_BASE="/mnt/smart/scratch/emm2/02-PROCESSED_DATA/SAGs_curated/SAGs_INDIVIDUAL"
AH_BASE="${SAG_BASE}/BL_SAGS_180508/75_david"
P_BASE="${SAG_BASE}/BL_SAGS_200915/227_Alacant"
GC_BASE="${SAG_BASE}/BL_SAGS_200915/31_Leuven"

total_listed=0
total_copied=0
total_copied_primary=0
total_copied_alt=0
total_missing=0

missing_report="scaffold_missing_sources.txt"
: > "$missing_report"


find_scaffold() {
    local sample="$1"
    local src=""
    local alt_base=""

    # 1) Always check main final genomes folder first
    src="${ICM_BASE}/${sample}/${sample}_filter3_scaffolds.fasta"
    if [[ -f "$src" ]]; then
        echo "$src"
        return 0
    fi

    # 2) If not found, choose alternative folder depending on sample prefix
    if [[ "$sample" == A* ]]; then
        alt_base="$AH_BASE"
    elif [[ "$sample" == P* ]]; then
        alt_base="$P_BASE"
    elif [[ "$sample" == GC* ]]; then
        alt_base="$GC_BASE"
    else
        return 1
    fi

    # 3) Try expected exact path in alternative folder
    src="${alt_base}/${sample}/${sample}_filter3_scaffolds.fasta"
    if [[ -f "$src" ]]; then
        echo "$src"
        return 0
    fi

    # 4) Flexible fallback in case file is deeper or slightly differently named
    src=$(find "${alt_base}/${sample}" -type f -name "*filter3*scaffolds*.fasta" 2>/dev/null | head -n 1 || true)
    if [[ -n "$src" && -f "$src" ]]; then
        echo "$src"
        return 0
    fi

    return 1
}


for listfile in "$LIST_DIR"/*_lists.txt; do
    [[ -e "$listfile" ]] || continue

    group=$(basename "$listfile" "_lists.txt")
    outdir="$OUT_BASE/${group}_scaffolds"

    rm -rf "$outdir"
    mkdir -p "$outdir"

    echo
    echo "Processing: $group"

    while IFS= read -r sample || [[ -n "$sample" ]]; do
        [[ -n "$sample" ]] || continue

        total_listed=$((total_listed + 1))

        if src=$(find_scaffold "$sample"); then
            dest="${outdir}/${sample}_filter3_scaffolds.fasta"

            cp "$src" "$dest"

            total_copied=$((total_copied + 1))

            if [[ "$src" == "$ICM_BASE"* ]]; then
                total_copied_primary=$((total_copied_primary + 1))
                echo "  OK primary: $sample"
            else
                total_copied_alt=$((total_copied_alt + 1))
                echo "  OK alternative: $sample"
                echo "    source: $src"
            fi

        else
            total_missing=$((total_missing + 1))
            echo "  MISSING: $sample"

            {
                echo "=================================================="
                echo "Sample: $sample"
                echo "Group: $group"
                echo
                echo "Checked primary:"
                echo "  ${ICM_BASE}/${sample}/${sample}_filter3_scaffolds.fasta"
                echo
                echo "Checked alternative:"
                if [[ "$sample" == AH* ]]; then
                    echo "  ${AH_BASE}/${sample}/"
                elif [[ "$sample" == P* ]]; then
                    echo "  ${P_BASE}/${sample}/"
                elif [[ "$sample" == GC* ]]; then
                    echo "  ${GC_BASE}/${sample}/"
                else
                    echo "  No alternative rule for this prefix"
                fi
                echo
            } >> "$missing_report"
        fi

    done < "$listfile"
done


echo
echo "========== COUNT CHECK =========="
echo "List total:              $total_listed"
echo "Copied total:            $total_copied"
echo "Copied from primary:     $total_copied_primary"
echo "Copied from alternative: $total_copied_alt"
echo "Missing total:           $total_missing"

if [[ "$total_listed" -eq "$total_copied" ]]; then
    echo "OK: all listed samples were copied"
else
    echo "ERROR: some listed samples were not copied"
    echo "Missing source report: $missing_report"
fi


echo
echo "========== CONTENT CHECK =========="

problem_report="scaffold_check_problems.txt"
: > "$problem_report"

problem_count=0

for listfile in "$LIST_DIR"/*_lists.txt; do
    [[ -e "$listfile" ]] || continue

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

    if [[ "$missing_n" -eq 0 && "$extra_n" -eq 0 ]]; then
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
            [[ "$missing_n" -gt 0 ]] && cat "$missing_tmp" || echo "(none)"
            echo
            echo "--- Extra sample IDs ---"
            [[ "$extra_n" -gt 0 ]] && cat "$extra_tmp" || echo "(none)"
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
echo "Missing source report: $missing_report"
