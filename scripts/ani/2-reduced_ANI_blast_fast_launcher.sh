#!/bin/sh

#SBATCH --account=emm2
#SBATCH --job-name=ANI
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --ntasks-per-node=1
#SBATCH --output=data/logs/ANIblast_%A_%a.out
#SBATCH --error=data/logs/ANIblast_%A_%a.err
#SBATCH --array=1-x%x
#================================================

#Load modules
module load blast
module load python/3.8.5


TAX=$(ls lists/ | sed 's/_lists.txt//g' | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 1


OUT=data/clean/reduced_blast_1to1s/${TAX}

#rm -r ${OUT}
mkdir -p ${OUT}

AR=data/clean/ANI_results_50/${TAX}_ANI_results

rm -r ${AR}
mkdir -p ${AR}


for SAMPLE in $(cat lists/${TAX}_lists.txt)
do

	# Initialize ANI result file for the current sample
	RESULT_FILE="${AR}/ANI_results_${SAMPLE}"
	> ${RESULT_FILE}  # Create or clear the result file for the sample

	for i in $(cat lists/${TAX}_lists.txt); 
	do 
	
		blastn \
			-query data/clean/temp_${TAX}/${i}_1k.split.1Kmer.fasta \
			-db data/clean/blastdb/${SAMPLE}_blastdb \
			-outfmt "6 qseqid length pident sseqid" \
			-max_hsps 1 \
			-qcov_hsp_perc 50 \
			-max_target_seqs 1 \
			-evalue 0.00001 \
			-num_threads 8 | \
			awk '$2 >= 500' > ${OUT}/blast_f_sc_${i}_to_${SAMPLE}; 

		h=$(cut -f 2 ${OUT}/blast_f_sc_${i}_to_${SAMPLE} | awk '{s+=$1} END {print s}'); 
	
		p=$(awk ' {print $2*$3/100}' ${OUT}/blast_f_sc_${i}_to_${SAMPLE} | awk '{s+=$1} END {print s/'"$h"'*100}'); 
	
		echo "${OUT}/blast_f_sc_${i}_to_${SAMPLE}  $h  $p" >> ${RESULT_FILE}
	
	done
done
