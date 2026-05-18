#!/usr/bin/env bash

set -euo pipefail

# Script to parse ANI blast results into tabular format

if [[ "$#" -ne 2 ]]; then
    echo
    echo "ERROR: You need to specify:"
    echo "  1st argument: list file with sample names"
    echo "  2nd argument: path where ANI_results files are located"
    echo
    echo "Usage:"
    echo "  bash scripts/ANI_results_parser.sh lists/tax10_lists.txt data/clean/reduced_blast_1to1s/tax10"
    exit 1
fi

list="$1"
data_path="$2"

if [[ ! -f "$list" ]]; then
    echo "ERROR: list file not found: $list"
    exit 1
fi

if [[ ! -d "$data_path" ]]; then
    echo "ERROR: data path not found: $data_path"
    exit 1
fi

tax=$(basename "$list" | sed 's/_lists\.txt$//')

out_dir="data/clean/ANI_tables_temp"
mkdir -p "$out_dir"

n_samples=$(grep -cv '^[[:space:]]*$' "$list")

echo
echo "Parsing ANI results"
echo "List file: $list"
echo "Data path: $data_path"
echo "Tax group: $tax"
echo "Samples: $n_samples"
echo "Output folder: $out_dir"
echo

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

#######################################
# ANI percentage table
#######################################

echo "Creating ANI percentage table..."

ani_per_header="${tmp_dir}/ANI_PER_00HEADER"
{
    echo "ANI_percentage"
    grep -v '^[[:space:]]*$' "$list"
} > "$ani_per_header"

count=0

while read -r sample; do
    [[ -z "$sample" ]] && continue

    count=$((count + 1))
    infile="${data_path}/ANI_results_${sample}"
    outfile="${tmp_dir}/ANI_PER_${sample}"

    echo "  [$count/$n_samples] Processing percentage: $sample"

    if [[ ! -f "$infile" ]]; then
        echo "    WARNING: missing file: $infile"
        {
            echo "$sample"
            yes "NA" | head -n "$n_samples"
        } > "$outfile"
        continue
    fi

    {
        echo "$sample"
        cut -f 5 -d " " "$infile" | sed 's/^$/NA/g'
    } > "$outfile"

done < "$list"

paste "${tmp_dir}"/ANI_PER_* > "${out_dir}/ANI_percentage_table_${tax}.txt"

echo "ANI percentage table written to:"
echo "  ${out_dir}/ANI_percentage_table_${tax}.txt"
echo

#######################################
# ANI length table
#######################################

echo "Creating ANI length table..."

ani_length_header="${tmp_dir}/ANI_LENGTH_00HEADER"
{
    echo "ANI_length"
    grep -v '^[[:space:]]*$' "$list"
} > "$ani_length_header"

count=0

while read -r sample; do
    [[ -z "$sample" ]] && continue

    count=$((count + 1))
    infile="${data_path}/ANI_results_${sample}"
    outfile="${tmp_dir}/ANI_LENGTH_${sample}"

    echo "  [$count/$n_samples] Processing length: $sample"

    if [[ ! -f "$infile" ]]; then
        echo "    WARNING: missing file: $infile"
        {
            echo "$sample"
            yes "NA" | head -n "$n_samples"
        } > "$outfile"
        continue
    fi

    {
        echo "$sample"
        cut -f 3 -d " " "$infile" | sed 's/^$/NA/g'
    } > "$outfile"

done < "$list"

paste "${tmp_dir}"/ANI_LENGTH_* > "${out_dir}/ANI_length_table_${tax}.txt"

echo "ANI length table written to:"
echo "  ${out_dir}/ANI_length_table_${tax}.txt"
echo
echo "Done."
