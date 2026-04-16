library(tidyverse) |> suppressMessages()

args <- commandArgs(trailingOnly = T)
db <- args[1]
sample <- args[2]

out_dir <- "data/diamond/comparison_reads/"
sags_file <- paste0("data/diamond/reads-vs-sags/",sample,"_100id_tax_lca.tsv")
db_file <- paste0("data/diamond/reads-vs-",db,"/",sample,"_100id_tax_lca.tsv")
out_overlap_file <- paste0(out_dir, sample, "_overlap_sags-vs-",db,"_100id.tsv")
out_no_overlap_sags_file <- paste0(out_dir, sample, "_no-overlap_sags-vs-",db,"_100id_sags.tsv")
out_no_overlap_db_file <- paste0(out_dir, sample, "_no-overlap_sags-vs-",db,"_100id_",db,".tsv")
  
sags_df <- 
  read_tsv(sags_file)

db_df <- 
  read_tsv(db_file)

overlap_df <- 
  sags_df |> 
  full_join(db_df) |> 
  filter(if_all(contains('lca_taxonomy'), ~ !is.na(.x))) |> 
  count(across(contains('lca_taxonomy'))) %>% arrange(-n)

sags_no_overlap <- 
  sags_df |> 
  filter(!qseqid %in% db_df$qseqid) |> 
  count(across(contains('lca_taxonomy'))) |> 
  arrange(-n)

db_no_overlap <- 
  db_df |> 
  filter(!qseqid %in% sags_df$qseqid) |> 
  count(across(contains('lca_taxonomy'))) |> 
  arrange(-n)

write_tsv(overlap_df, out_overlap_file)
write_tsv(sags_no_overlap, out_no_overlap_sags_file)
write_tsv(db_no_overlap, out_no_overlap_db_file)
