library(tidyverse) |> suppressMessages()

args <- commandArgs(trailingOnly = T)
db <- args[1]

samples <- 
  read_lines('data/metag_samples.txt')

tabs <- 
  samples |> 
  map(~read_tsv(paste0('data/diamond/reads-vs-',db,'/',.x,'_100id_tax_summary.tsv')) |> 
        mutate(sample = .x)) |> 
  bind_rows()

order <- 
  tabs |> 
  group_by(lca_taxonomy) |> 
  summarise(n = sum(n)) |> 
  arrange(-n)

otutab <- 
  tabs |> 
  mutate(lca_taxonomy = factor(lca_taxonomy, levels = order$lca_taxonomy)) |> 
  arrange(lca_taxonomy) |> 
  pivot_wider(names_from = sample, values_from = n, values_fill = 0)

write_tsv(otutab, file = paste0('data/diamond/reads-vs-',db,'/otutab_',db,'_100id_tax_summary.tsv'))

