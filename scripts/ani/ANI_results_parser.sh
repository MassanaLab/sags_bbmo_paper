#!/bin/bash

# Script to parse ANI blast results into tabular format

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo -e "\nERROR! You need to specify:"
    echo "  1st: Name of the list file"
    echo "  2nd: Path where ANI_results files are located"
    exit 1
fi

# Define variables
list="$1"
data_path="$2"

tax=$(basename "$list" | sed 's/_lists\.txt$//')

OUT=data/clean/ANI_tables_temp

mkdir -p ${OUT}


echo -e "\n\n>> Hi, Let's get the results in tabular format! <<\n"


# Process ANI percentages
echo -e "ANI_percentage" > ANI_PER_00HEADER
cat "$list" >> ANI_PER_00HEADER

while read -r line; do 

    echo -e "${line}" > ANI_PER_${line}
    cut -f 5 -d " " "${data_path}/ANI_results_${line}" | sed 's/^$/NA/g' >> ANI_PER_${line}

done < "$list"

paste ANI_PER_* > ${OUT}/ANI_percentage_table_${tax}.txt
rm ANI_PER_*


# Process ANI lengths (FIXED)

echo -e "ANI_length" > ANI_LENGTH_00HEADER
cat "$list" >> ANI_LENGTH_00HEADER

while read -r line; do

    echo -e "${line}" > ANI_LENGTH_${line}
    cut -f 3 -d " " "${data_path}/ANI_results_${line}" | sed 's/^$/NA/g' >> ANI_LENGTH_${line}

done < "$list"

paste ANI_LENGTH_* > ${OUT}/ANI_length_table_${tax}.txt

rm ANI_LENGTH_*


echo -e "\n\n>> DONE! :=) <<\n"
