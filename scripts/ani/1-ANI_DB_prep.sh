#!/bin/sh

#SBATCH --account=emm2
#SBATCH --job-name=ANI
#SBATCH --mem=50G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --output=data/logs/ANI_DB_prep_%A_%a.out
#SBATCH --error=data/logs/ANI_DB_prep_%A_%a.err
#SBATCH --array=1-12%4

DATA_PATH=data/clean/blastdb

mkdir -p ${DATA_PATH}

TAX=$(ls lists/ | sed 's/_lists.txt//g' | awk "NR == ${SLURM_ARRAY_TASK_ID}")

# Load modules
module load blast
module load python/3.8.5
module load seqkit

echo "Processing: ${TAX}"

rm -r data/clean/temp_${TAX}
mkdir -p data/clean/temp_${TAX}

while IFS= read -r SAMPLE; do

    echo "  Sample: ${SAMPLE}"

    # Path to original scaffolds (adjust pattern if needed)
    SCAFF=data/clean/scaffolds_needed/${TAX}_scaffolds/${SAMPLE}*.fasta

    # If your filenames really are like ${SAMPLE}*.fasta, then:
    SCAFF=$(ls data/clean/scaffolds_needed/${TAX}_scaffolds/${SAMPLE}*.fasta)

    # OPTIONAL: filter sequences > 1000 bp into a "clean" scaffolds file
    # (this step is not strictly required for the DB; you can use SCAFF directly)
    seqkit seq -m 1000 "$SCAFF" > data/clean/temp_${TAX}/${SAMPLE}_1k.fasta

    # Split sequences into 1 kb fragments with 10 bp overlap for QUERIES
    pyfasta split \
        -k 1000 \
        -n 1 \
        data/clean/temp_${TAX}/${SAMPLE}_1k.fasta 

	# pyfasta will create: data/clean/temp_${TAX}/${SAMPLE}_1k.fasta.0
	# Rename it to something nice:
	mv data/clean/temp_${TAX}/${SAMPLE}_1k.fasta.0 \
	data/clean/temp_${TAX}/${SAMPLE}_1k.split.1Kmer.fasta

    # Create BLAST database from the **UNCUT** scaffolds
    # Option A: from full scaffolds
    makeblastdb \
        -in "$SCAFF" \
        -dbtype nucl \
        -out ${DATA_PATH}/${SAMPLE}_blastdb

    # Option B (if you prefer DB only with >=1kb scaffolds):
    # makeblastdb \
    #     -in data/clean/temp_${TAX}/${SAMPLE}_1k.fasta \
    #     -dbtype nucl \
    #     -out ${DATA_PATH}/${SAMPLE}_blastdb

done < lists/${TAX}_lists.txt
