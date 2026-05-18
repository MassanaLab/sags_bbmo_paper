library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop(
    "ERROR: Please provide one argument for the output folder name.\n",
    "Example:\n",
    "  Rscript scripts/7-histograms_ANI_review.R review99\n"
  )
}

run_name <- args[1]

base_dir <- "data/clean/reduced_blast_1to1s"
out_dir  <- paste0("blast_distributions_jpg_", run_name)

# create output folder if it doesn't exist
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# get all tax folders
tax_dirs <- list.dirs(base_dir, recursive = FALSE, full.names = TRUE)

# function to read one blast file
read_blast_file <- function(file) {
  fname <- basename(file)

  # remove prefix
  comp <- str_remove(fname, "^blast_f_sc_")

  # remove possible file extension
  comp <- str_remove(comp, "\\.[^.]+$")

  # split sample names
  parts <- str_split(comp, "_to_", simplify = TRUE)

  sample_x <- parts[1]
  sample_y <- parts[2]

  # read file
  df <- read_table(
    file,
    col_names = FALSE,
    show_col_types = FALSE
  )

  # add comparison labels
  df %>%
    mutate(
      sample_x = sample_x,
      sample_y = sample_y
    )
}

# loop through each tax folder
for (tax_dir in tax_dirs) {

  tax_name <- basename(tax_dir)
  message("Processing ", tax_name)

  # get blast files inside this tax folder
  files <- list.files(tax_dir, full.names = TRUE)

  # skip empty folders
  if (length(files) == 0) {
    message("  No files found in ", tax_name)
    next
  }

  # read and combine all blast files
  blast_all <- map_dfr(files, read_blast_file)

  # make plot
  p <- blast_all %>%
    filter(sample_x != sample_y) %>%
    ggplot(aes(x = X3)) +
    geom_histogram(
      binwidth = 1,
      boundary = 100,
      closed = "right"
    ) +
    facet_grid(sample_x ~ sample_y, scales = "free_y") +
    coord_cartesian(xlim = c(70, 100)) +
    labs(
      title = tax_name,
      x = "Similarity (%)",
      y = "Number of contigs"
    ) +
    theme_minimal() +
    theme(
      strip.text = element_text(size = 8),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )

  # save jpg
  ggsave(
    filename = file.path(out_dir, paste0(tax_name, ".jpg")),
    plot = p,
    width = 14,
    height = 14,
    dpi = 600
  )
}

message("Done. JPG files saved in: ", out_dir)
