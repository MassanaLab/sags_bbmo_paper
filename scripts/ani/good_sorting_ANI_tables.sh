#!/bin/bash

W=$1

OUT=data/clean/ANI_tables_sorted

mkdir -p ${OUT}

for TAX in $(ls lists/ | sed 's/_lists.txt//g')
do

	input_file="data/clean/ANI_tables_temp/ANI_percentage_table_${TAX}.txt"
	output_file="${OUT}/ANI_${W}_percentage_table_${TAX}_sorted.txt"

	awk '
	NR==1 { 
    	# Save header order
    	for (i=2; i<=NF; i++) header[i-1] = $i 
    	next 
	} 
	{ 
    	# Store the entire row using the first column as key
    	for (i=2; i<=NF; i++) matrix[$1][header[i-1]] = $i
    	order[NR-1] = $1
	} 
	END { 
	    # Sort order lexicographically
	    n = asort(order)
    
    	# Print sorted header
    	printf "ANI_percentage" > "'"$output_file"'"
    	for (i=1; i<=n; i++) printf "\t%s", order[i] >> "'"$output_file"'"
    	print "" >> "'"$output_file"'"
    
    	# Print sorted rows
    	for (i=1; i<=n; i++) {
        	printf "%s", order[i] >> "'"$output_file"'"
        	for (j=1; j<=n; j++) printf "\t%s", matrix[order[i]][order[j]] >> "'"$output_file"'"
        	print "" >> "'"$output_file"'"
    	}
    	print "Sorted table saved to: '"$output_file"'"
	}' "$input_file"

done

for TAX in $(ls lists/ | sed 's/_lists.txt//g')
do

        input_file="data/clean/ANI_tables_temp/ANI_length_table_${TAX}.txt"
        output_file="${OUT}/ANI_${W}_length_table_${TAX}_sorted.txt"

        awk '
	NR==1 {
        # Save header order
        for (i=2; i<=NF; i++) header[i-1] = $i
        next
	}
	{
	# Store the entire row using the first column as key
        for (i=2; i<=NF; i++) matrix[$1][header[i-1]] = $i
        order[NR-1] = $1
        }
	END {
            # Sort order lexicographically
            n = asort(order)

        # Print sorted header
        printf "ANI_length" > "'"$output_file"'"
        for (i=1; i<=n; i++) printf "\t%s", order[i] >> "'"$output_file"'"
        print "" >> "'"$output_file"'"

        # Print sorted rows
        for (i=1; i<=n; i++) {
                printf "%s", order[i] >> "'"$output_file"'"
                for (j=1; j<=n; j++) printf "\t%s", matrix[order[i]][order[j]] >> "'"$output_file"'"
                print "" >> "'"$output_file"'"
        }
	print "Sorted table saved to: '"$output_file"'"
        }' "$input_file"

done
