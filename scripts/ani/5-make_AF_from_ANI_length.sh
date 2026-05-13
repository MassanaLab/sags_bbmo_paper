#!/bin/bash

W=50

# Directory where the sorted ANI_length tables are
IN_DIR="data/clean/ANI_tables_sorted"
OUT_DIR="data/clean/ANI_tables_sorted"   # same place, different prefix; change if you want

mkdir -p "${OUT_DIR}"

for TAX in $(ls lists/ | sed 's/_lists.txt//g'); do
    input_file="${IN_DIR}/ANI_${W}_length_table_${TAX}_sorted.txt"
    output_file="${OUT_DIR}/AF_${W}_table_${TAX}_sorted.txt"

    if [[ ! -f "$input_file" ]]; then
        echo "WARNING: ${input_file} not found, skipping ${TAX}"
        continue
    fi

    echo "Computing AF matrix for ${TAX} from ${input_file}"

    awk -v OFS="\t" '
        NR==1 {
            # Header row: store column names (genome IDs)
            for (i=2; i<=NF; i++) header[i-1] = $i
            n = NF-1
            next
        }
        {
            row = $1
            order[NR-1] = row
            for (i=2; i<=NF; i++) {
                val[row, header[i-1]] = $i
            }
        }
        END {
            # Diagonal: self-alignment lengths Lii
            for (i=1; i<=n; i++) {
                r = order[i]
                diag[r] = val[r, r]
            }

            # Print header: AF + sorted genome IDs
            printf "AF"
            for (i=1; i<=n; i++) {
                printf OFS "%s", order[i]
            }
            printf "\n"

            # Print rows
            for (i=1; i<=n; i++) {
                r = order[i]
                printf "%s", r
                d = diag[r]

                for (j=1; j<=n; j++) {
                    c = order[j]
                    v = val[r, c]

                    if (r == c) {
                        # Self AF is 100%
                        printf OFS "100"
                    } else if (v == "NA" || d == "NA" || d == 0) {
                        # Missing or zero denominator → NA
                        printf OFS "NA"
                    } else {
                        af = (v + 0) / (d + 0) * 100
                        printf OFS "%0.4f", af
                    }
                }
                printf "\n"
            }
        }
    ' "$input_file" > "$output_file"

    echo "  -> AF matrix saved to: ${output_file}"
    echo
done
