

output_file="data/clean/ANI_percentage_combined.tsv"

# Empty the output file if it exists
> "$output_file"

# Loop through each file
for file in data/clean/ANI_tables_sorted/ANI*percentage_table_*_sorted.txt; do
    # Extract the filename without path and extension
    name=$(basename "$file" .txt | sed 's/ANI_percentage_table_//')

    # Append the filename as a header and then the file contents
    echo -e "$name" >> "$output_file"
    cat "$file" >> "$output_file"
    echo "" >> "$output_file"  # Add an empty line for separation
done

echo "Result in $output_file"

output_file="data/clean/ANI_length_combined.tsv"

# Empty the output file if it exists
> "$output_file"

# Loop through each file
for file in data/clean/ANI_tables_sorted/ANI*length_table_*_sorted.txt; do
    # Extract the filename without path and extension
    name=$(basename "$file" .txt | sed 's/ANI_length_table_//')

    # Append the filename as a header and then the file contents
    echo -e "$name" >> "$output_file"
    cat "$file" >> "$output_file"
    echo "" >> "$output_file"  # Add an empty line for separation
done

echo "Result in $output_file"
