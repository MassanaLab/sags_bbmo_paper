require(tidyverse)

topgo_enricher <- function(ontology, universe_genes, sag_genes, algorithm = "weight01") {
  # annotation must be a named list with gene name and all its associated GO terms
  # de genes is just a list of gene names that are DE (or that have some interest)

  require(topGO)

  genes <-
    tibble(
      gene = c(names(universe_genes), names(sag_genes)),
      de = factor(c(rep(0, length(universe_genes)), rep(1, length(sag_genes))))
    ) |>
    deframe()

  annotation <-
    c(universe_genes, sag_genes)

  topgo_object <-
    new("topGOdata",
      ontology = ontology,
      allGenes = genes,
      annot = annFUN.gene2GO,
      gene2GO = annotation
    )

  resultFisher <- runTest(topgo_object, algorithm = algorithm, statistic = "fisher")

  GenTable(topgo_object,
    classic = resultFisher,
    orderBy = "weight",
    topNodes = 100,
    numChar = 1000
  ) |>
    as_tibble() |>
    mutate(classic = as.numeric(classic)) |>
    filter(classic <= 0.05)
}

args <- commandArgs(trailingOnly = T)
universe_genes <- readRDS(args[1])
sag_genes <- readRDS(args[2])
out_file <- args[3]

ontologies <- c("BP", "CC", "MF")

enrichment_df <-
  ontologies |>
  set_names() |>
  map(~ topgo_enricher(
    ontology = .x,
    universe_genes = universe_genes,
    sag_genes = sag_genes
  )) |>
  bind_rows(.id = "ontology")

write_tsv(enrichment_df, out_file)

