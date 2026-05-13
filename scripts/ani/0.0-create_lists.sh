# make sure you have a table with each sample and its corresponding tax (grups.txt)

mkdir -p lists

awk '
BEGIN { FS="[[:space:]]+" }
NR == 1 { next }

{
    sample = $1
    tax = $NF

    if (sample != "" && tax != "") {
        samples[tax] = samples[tax] sample "\n"
        count[tax]++
    }
}

END {
    for (tax in count) {
        if (count[tax] > 1) {
            file = "lists/tax" tax "_lists.txt"
            printf "%s", samples[tax] > file
            close(file)
        }
    }
}
' grups.txt
