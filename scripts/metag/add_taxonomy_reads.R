library(tidyverse) |> suppressMessages()

get_lca <- function(tax_strings) {
  
  # No LCA to compute if only one taxonomy string
  if (length(tax_strings) == 1){
    return(tax_strings)
  }
  
  # Split strings into lists of vectors
  split_tax <- str_split(tax_strings, ";")
  
  # Find the shortest depth to avoid index errors
  min_len <- min(map_int(split_tax, length))
  if (min_len == 0) return(NA_character_)
  
  # Truncate all vectors to the minimum length and bind them into a matrix
  # This allows us to compare column by column (rank by rank)
  mat <- split_tax %>%
    map(~ .x[1:min_len]) %>%
    do.call(rbind, .)
  
  # Iterate through columns to find matches
  consensus <- c()
  for (i in 1:ncol(mat)) {
    # If there is only 1 unique value in this column, it is a match
    if (n_distinct(mat[, i]) == 1) {
      consensus <- c(consensus, mat[1, i])
    } else {
      break # Stop immediately at the first mismatch
    }
  }
  
  # Reassemble
  result <- paste0('lca:',paste(consensus, collapse = ";"))
}

add_taxonomy_reads <- function(diamond_file, db){
  
  reads_df <- 
    read_tsv(diamond_file, 
             col_names = c('qseqid','sseqid','pident','length')) |> 
    rename_with(.cols = -qseqid, .fn = ~paste0(.x, '_',db))
  
  if (db == 'sags'){
    
    out_df <-
      reads_df |> 
      mutate(sag_id = str_remove(sseqid_sags, '_g.*')) |> 
      distinct(qseqid, sag_id) |> 
      mutate(sags_tax = paste0(str_remove(sag_id, '.*_'),';',str_match(sag_id, '(.*)_')[,2]))
    
  } else if (db == 'eukprot'){
    
    eukprot_tax <- 
      read_tsv('data/db/EukProt_tax.txt') |> 
      select(eukprot_id = 1, eukprot_tax = 2)
    
    out_df <- 
      reads_df |> 
      mutate(eukprot_id = str_remove(sseqid_eukprot, '_.*')) |>
      distinct(qseqid, eukprot_id) |> 
      left_join(eukprot_tax)
    
  } else if (db == 'marferret'){
    
    marferret_proteins <-
      read_tsv('data/db/marferret/MarFERReT.v1.1.1.proteins_info.tab.gz', col_select=c(1,2)) |> 
      rename(sseqid_marferret = aa_id)
    
    marferret_tax <- 
      read_tsv('data/db/marferret/MarFERReT.v1.1.1.tax.tsv')
    
    out_df <- 
      reads_df |>
      left_join(marferret_proteins) |>
      distinct(qseqid, entry_id) |>
      left_join(marferret_tax) |> 
      select(qseqid, marferret_id = entry_id, marferret_tax = lineage)
      
    
  }
  
  unique_df <- 
    out_df |> 
    group_by(qseqid) |> 
    filter(n() == 1)
  
  consensus_tax <- 
    out_df |> 
    select(taxonomy = 3, everything()) |> 
    group_by(qseqid) |> 
    summarise(lca_taxonomy = get_lca(taxonomy))
    
  lca_df <- 
    consensus_tax |> 
    rename_with(.cols = -qseqid, .fn = ~paste0(db,'_',.x))
  
  summary_df <- 
    consensus_tax |> 
    count(lca_taxonomy) |> 
    arrange(-n)
  
  result <- list(all = out_df,
              unique = unique_df,
              lca = lca_df,
              summary = summary_df)
  
  return(result)
  
}

args <- commandArgs(trailingOnly = T)
diamond_file <- args[1]
db <- args[2]
out_path <- args[3]

result <- 
  add_taxonomy_reads(diamond_file, db)

c('all','unique','lca','summary') |> 
  walk(~ write_tsv(result[[.x]], file =  paste0(out_path,'_',.x,'.tsv')))
