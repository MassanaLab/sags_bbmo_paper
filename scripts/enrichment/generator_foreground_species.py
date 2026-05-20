#!/usr/bin/env python3
"""
generator_foreground_species.py

Create foreground Pfam domain counts for each species. It takes the domain information from InterProScan annotations within species annotation subfolders
Pfam-A.clans.tsv file required

usage: 

python3 generator_foreground_species.py \
  -s specieslist \
  -d ~SAGs_FINAL_GENOMES/ \
  -m Pfam-A.clans.tsv \
  -o outputfolder

generator_foreground_species.py

Authorship
López-Escardó, David

Contact: david.lopez.escardo@gmail.com

Created: 2025-07

"""

import os
import argparse
import pandas as pd

def load_pfam_mapping(mapping_file):
    pfam_df = pd.read_csv(mapping_file, sep="\t", header=None, compression="infer")
    pfam_df.columns = ["pfam_id", "clan_id", "clan_name", "pfam_name", "pfam_description"]
    return pfam_df[["pfam_id", "pfam_name"]].drop_duplicates()

def process_species_file(species, base_path, pfam_mapping):
    pfam_file = os.path.join(base_path, species, f"{species}_filter3_interproscan_pfam.tsv")
    if not os.path.isfile(pfam_file):
        print(f"❌ Missing file: {pfam_file}")
        return None

    try:
        df = pd.read_csv(pfam_file, sep="\t", header=None)
        df.columns = ["gene", "md5", "length", "source", "pfam_id", "pfam_name",
                      "start", "end", "evalue", "is_significant", "date",
                      "ipr_id", "ipr_name", "unknown1", "unknown2"]

        # Keep only valid Pfam entries
        pfam_counts = df[df["source"] == "Pfam"]["pfam_id"].value_counts().reset_index()
        pfam_counts.columns = ["pfam_id", "count"]

        # Add pfam names
        merged = pfam_counts.merge(pfam_mapping, on="pfam_id", how="left")
        merged = merged.dropna(subset=["pfam_name"])
        merged["species"] = species
        merged = merged.rename(columns={"pfam_name": "annot"})[["annot", "count", "species"]]

        output_file = os.path.join(base_path, species, f"{species}_foreground_pfam.txt")
        merged.to_csv(output_file, sep="\t", index=False)
        print(f"✅ Written: {output_file}")

    except Exception as e:
        print(f"⚠️ Error processing {pfam_file}: {e}")

def main():
    parser = argparse.ArgumentParser(description="Generate foreground domain counts per species")
    parser.add_argument("-s", "--species_list", required=True, help="File with list of species names")
    parser.add_argument("-d", "--directory", required=True, help="Base directory with species subfolders")
    parser.add_argument("-m", "--mapping", required=True, help="Pfam-A.clans.tsv file for mapping PFxxxxx to names")

    args = parser.parse_args()

    # Load Pfam mapping
    pfam_mapping = load_pfam_mapping(args.mapping)

    # Load species list
    with open(args.species_list, 'r') as f:
        species_list = [line.strip() for line in f if line.strip()]

    for species in species_list:
        process_species_file(species, args.directory, pfam_mapping)

if __name__ == "__main__":
    main()
