library(tidyverse) |> suppressMessages()
library(Biostrings) |> suppressMessages()

args <- commandArgs(trailingOnly = T)

genes_list <- args[1]
fasta_file <- args[2]

genes_df <- 
  read_tsv(genes_list, col_names = c('gene','start','end'))

fasta <- 
  readAAStringSet(fasta_file)

fasta_df <- 
  tibble(
    gene = names(fasta),
    seq = as.character(fasta)
  )

genes_trimmed <- 
  genes_df |> 
  left_join(fasta_df) |> 
  mutate(trimmed_seq = substr(seq, start, end)) |> 
  group_by(gene) |> 
  mutate(new_names = case_when(
    n() > 1 ~ str_c(gene, "_", row_number()),
    TRUE    ~ gene
  ))

fasta_trimmed <- 
  genes_trimmed |> 
  ungroup() |> 
  select(new_names, trimmed_seq) |> 
  deframe() |> 
  AAStringSet()

writeXStringSet(fasta_trimmed, str_c(tools::file_path_sans_ext(fasta_file),'_trimmed.fasta'))