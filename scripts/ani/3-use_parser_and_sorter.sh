rm -r data/clean/ANI_tables_temp/

rm -r data/clean/ANI_tables_sorted/


W=50

for TAX in $(ls lists/ | sed 's/_lists.txt//g')
do

	bash \
		scripts/ANI_results_parser.sh \
		lists/${TAX}_lists.txt \
		data/clean/ANI_results_${W}/${TAX}_ANI_results/

done


bash scripts/good_sorting_ANI_tables.sh ${W}
