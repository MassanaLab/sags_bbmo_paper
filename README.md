# Single-cell sequencing reveals genome streamlining and functional diversity in ecologically dominant marine protists

This repository contains code and data included in:

--------
López-Escardó, D., Obiol, A., Marimon, G., López-Alforja, X., Vaqué, D., Forn, I., Logares, R., Yau, S., Fornas, O., Martínez-García, M., and Massana R. Single-cell sequencing reveals genome streamlining and functional diversity in ecologically dominant marine protists.

--------

- [How were the SAGs built](#how-were-the-sags-built)
- [How to download the SAGs dataset](#how-to-download-the-sags-dataset)
- [Scripts used to obtain data for figures](#scripts-used-to-obtain-data-for-figures)
- [Scripts to reproduce all figures](#scripts-to-reproduce-all-figures)
- [Where to find raw data](#where-to-find-raw-data)

## How were the SAGs built

The pipeline used to build SAGs can be found in the dedicated repository [MassanaLab/SAGs-pipeline](https://github.com/MassanaLab/SAGs-pipeline).

## How to download the SAGs dataset

The dataset (and associated metadata) is available at Zenodo: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18786764.svg)](https://doi.org/10.5281/zenodo.18786764).

You can directly download it with:

```
wget -O sags_bbmo.tar.gz https://zenodo.org/records/18786764/files/sags_bbmo.tar.gz?download=1&preview=1
```

Then, uncompress:

```
tar -xvzf sags_bbmo.tar.gz
```

And verify file integrity: 

```
cd sags_bbmo
md5sum -c md5sum.txt
```

## Scripts used to obtain data for figures

The scripts to process SAGs and obtain the date used for figures can be found in the following directories:

- Phylogenomic tree construction: [`scripts/phylofisher/`](scripts/phylofisher/). 
- Creating databases for mapping and quantification: [`scripts/create_dbs/`](scripts/create_dbs/).
- Mapping BBMO metagenomes against MarFERReT and SAGs: [`scripts/metag/`](scripts/metag/).
- Quantifying SAGs functional genes with BBMO metaT: [`scripts/metat/`](scripts/metat/).
- GO enrichment analysis: [`scripts/enrichment/`](scripts/enrichment/) using data prepared in script [`scripts/enrichment/prepare_files_enrichment.Rmd`](scripts/enrichment/prepare_files_enrichment.Rmd). Already prepared data is also available at [`data/enrichment/enrichment_files/`](data/enrichment/enrichment_files/).

The following software is needed:

```
cutadapt
diamond
openjdk
phylofisher
R
seqkit
salmon
```

## Scripts to reproduce all figures

1. Download all scripts and data by using:

```
git clone https://github.com/MassanaLab/sags_bbmo_natmicrobiol.git
```

2. Install the following R packages: 

```
ape
cowplot
ggh4x
ggnewscale
ggrastr
ggsci
ggtext
ggtree
patchwork
scales
speedyseq
tidytree
tidyverse
viridis
```

3. Open the R scripts (.Rmd) inside [`scripts/figure_scripts/`](scripts/figure_scripts/) and run the code.

## Where to find raw data

Raw data can be found here:

|Dataset    |Accession number |
|:----------|:--------------------|
|SAGs       |[PRJEB108838](https://www.ebi.ac.uk/ena/browser/view/PRJEB108838)                  |
|BBMO metaG |[PRJEB51979](https://www.ebi.ac.uk/ena/browser/view/PRJEB51979)                  |
|BBMO metaT |XXX                  |

For SAGs, a metadata table showing the correspondence between ENA accession numbers and sample names can be found [here](data/sags/sags_bbmo_ena_metadata.tsv).
