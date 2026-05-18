# This script requires the text file from the previous script (0.1-clean_grups.sh). It will create a list file for each 
# tax number, containing all samples that belong to that tax.

mkdir -p lists

awk '
{
    print $1 > "lists/tax"$2"_lists.txt"
}
' grups_only_shared_taxa.txt
