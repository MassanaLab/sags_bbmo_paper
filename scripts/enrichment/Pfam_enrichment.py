import pandas as pd
import scipy.stats as stats
from statsmodels.stats.multitest import multipletests
import argparse
import os

"""
Pfam_enrichment.py		usage: Pfam_enrichment.py -b filtered_EukprotTCS_background072025.tsv -f species_foreground_pfam.txt -o outputfolder/outputfilename								
																																														
pfam enrichment test to extract the enriched domains of a given species:																													
The scripts needs its foreground table domain file, the background file based in EukProt wihthout multicellular lineages																	
It is set to pval threshol of 0,05 and a minimum count of 3 domains in the species for the domain to be classified as enriched and deposited in outputfilename_foreground_enrich.txt file	


Authorship: 

López-Escardó, David

Contact: david.lopez.escardo@gmail.com

Created: 2025-07
"""

def perform_enrichment_analysis(background_file, foreground_file, output_name, pval_threshold=0.05, fgcount_threshold=3):
    # Load background and foreground data
    background_data = pd.read_csv(background_file, sep='\t')
    foreground_data = pd.read_csv(foreground_file, sep='\t')
    
    # Merge the background and foreground data
    combined_data = pd.merge(background_data, foreground_data, on='annot', how='outer', suffixes=('_bg', '_fg')).fillna(0)
    
    # Calculate p-values using Fisher's exact test
    combined_data['pval'] = combined_data.apply(lambda row: stats.fisher_exact([[row['count_fg'], row['count_bg']], 
                                                                              [sum(combined_data['count_fg']) - row['count_fg'], 
                                                                               sum(combined_data['count_bg']) - row['count_bg']]])[1], axis=1)
    
    # Adjust p-values for multiple testing using Benjamini-Hochberg method
    combined_data['pval_adj'] = multipletests(combined_data['pval'], method='fdr_bh')[1]
    
    # Save the full results to the first output file
    full_output_file = f"{output_name}_enrich_results.txt"
    combined_data.to_csv(full_output_file, sep='\t', index=False)
    print(f"Full enrichment results saved to {full_output_file}")

    # Filter for significant results
    significant_data = combined_data[(combined_data['count_fg'] > fgcount_threshold) & (combined_data['pval_adj'] < pval_threshold)]
    
    # Add species information columns
    significant_data['species'] = foreground_data['species'].groupby(foreground_data['annot']).apply(lambda x: ','.join(x)).reindex(significant_data['annot']).values
    significant_data['species_count'] = significant_data['species'].apply(lambda x: len(x.split(',')) if pd.notna(x) else 0)
    
    # If there are duplicate annotations, keep the one with the highest count_fg
    significant_data = significant_data.loc[significant_data.groupby('annot')['count_fg'].idxmax()]

    # Save the significant results to the second output file
    significant_output_file = f"{output_name}_foreground_enrich.txt"
    significant_data.to_csv(significant_output_file, sep='\t', index=False)
    print(f"Significant enrichment results saved to {significant_output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Perform enrichment analysis on PFAM domains.")
    parser.add_argument("-b", "--background", required=True, help="Path to the background file")
    parser.add_argument("-f", "--foreground", required=True, help="Path to the foreground file")
    parser.add_argument("-o", "--output", required=True, help="Base name for output files")
    parser.add_argument("--pval", type=float, default=0.05, help="Adjusted p-value threshold for significance")
    parser.add_argument("--fgcount", type=int, default=3, help="Minimum count_fg threshold for significance")
    
    args = parser.parse_args()
    
    perform_enrichment_analysis(args.background, args.foreground, args.output, args.pval, args.fgcount)