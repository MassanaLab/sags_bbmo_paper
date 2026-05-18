# This script requires and input textfile (grups.txt) with just two columns: sample and tax number. The script will select only those 
# those samples that belong to a taxa group = those that are not alone.

awk '
BEGIN{OFS="\t"}
{
    sample[NR]=$1
    tax[NR]=$NF
    count[$NF]++
}
END{
    for (i=1; i<=NR; i++) {
        if (count[tax[i]] > 1) {
            print sample[i], tax[i]
        }
    }
}
' grups.txt > grups_only_shared_taxa.txt
