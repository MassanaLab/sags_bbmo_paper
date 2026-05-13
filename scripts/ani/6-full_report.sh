#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "ERROR: you must provide a keyword for the output filename"
    echo "Usage: $0 <keyword>"
    exit 1
fi

KEYWORD="$1"
W=50

output="data/clean/ANI_tables_sorted/ALL_${W}_${KEYWORD}_ANI_AF_combined.tsv"
> "$output"

for TAX in $(ls lists/ | sed 's/_lists.txt//' | sort -V); do
    echo "=== TAX GROUP: $TAX ===" >> "$output"
    echo "" >> "$output"

    ANI="data/clean/ANI_tables_sorted/ANI_${W}_percentage_table_${TAX}_sorted.txt"
    LEN="data/clean/ANI_tables_sorted/ANI_${W}_length_table_${TAX}_sorted.txt"
    AF="data/clean/ANI_tables_sorted/AF_${W}_table_${TAX}_sorted.txt"

    if [[ -f "$ANI" ]]; then
        echo "[ ANI_percentage ]" >> "$output"
        cat "$ANI" >> "$output"
        echo "" >> "$output"
    fi

    if [[ -f "$LEN" ]]; then
        echo "[ ANI_length ]" >> "$output"
        cat "$LEN" >> "$output"
        echo "" >> "$output"
    fi

    if [[ -f "$AF" ]]; then
        echo "[ AF_alignment_fraction ]" >> "$output"
        cat "$AF" >> "$output"
        echo "" >> "$output"
    fi

    echo "--------------------------------------------------" >> "$output"
    echo "" >> "$output"
done

echo "Combined report written to: $output"
