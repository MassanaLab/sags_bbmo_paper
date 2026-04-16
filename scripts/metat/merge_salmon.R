library(tidyverse)

samples <- read_lines('data/metat_samples.txt')
data.dir <- 'data/salmon/'
out.file <- paste0(data.dir,'/sags_metat_abundance_tpm.tsv')

tpm_df <-
  samples %>%
  map(.x = .,
      .f = ~ read_tsv(paste(data.dir,.x,'quant.sf', sep = '/')) %>% select(Name, Length, !!.x := TPM)) %>% 
  reduce(full_join, by = c('Name','Length'))

write_tsv(tpm_df, out.file)
