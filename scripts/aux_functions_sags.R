require(patchwork) |> suppressMessages()
require(speedyseq) |> suppressMessages()
require(ggtext) |> suppressMessages()
require(ggtree) |> suppressMessages()
require(tidytree) |> suppressMessages()
require(ape) |> suppressMessages()
require(viridis) |> suppressMessages()
require(cowplot) |> suppressMessages()
require(ggsci) |> suppressMessages()
require(ggrastr) |> suppressMessages()
require(ggh4x) |> suppressMessages()
require(ggforce) |> suppressMessages()
require(ggnewscale) |> suppressMessages()
require(tidyverse) |> suppressMessages()


# General plotting functions ----------------------------------------------

theme_sags <- function() {
  theme_bw() +
    theme(
      panel.grid = element_blank(),
      strip.background = element_rect(fill = NA),
      strip.text = element_text(size = 8),
      legend.text = element_text(size = 8),
      axis.text = element_text(size = 8),
      legend.title = element_text(size = 9),
      axis.title = element_text(size = 9),
      legend.background = element_blank(),
      plot.background = element_blank()
    )
}

scientific_10 <- function(x) {
  out <- scales::scientific_format()(x)

  out[x == 0] <- "0"

  parse(text = gsub("e", " %*% 10^", out))
}

percentage <- function(x) {
  100 * x / sum(x)
}

# Functions for flow cytometry data ---------------------------------------

fcs_to_df <- function(fcs_file) {
  require(flowCore) |> suppressMessages()

  flow_frame <- read.FCS(fcs_file)
  data_matrix <- exprs(flow_frame)
  data_df <- as.data.frame(data_matrix) |> as_tibble()

  return(data_df)
}

plot_cytogram <- function(fcs_df,
                          xcol = "PE",
                          ycol = "PECY5",
                          limits_x = c(1, 1e4),
                          limits_y = c(1, 1e4),
                          alpha_points = 0.1,
                          size_points = 0.5) {
  lines_color <- scales::col_mix("black", "white", .2) # default for theme_bw
  linewidth <- 0.3

  p_cytogram <-
    fcs_df |>
    ggplot(aes(x = !!sym(xcol), y = !!sym(ycol))) +
    geom_point(color = "gray20", size = size_points, alpha = alpha_points) +
    scale_x_log10(
      labels = scales::label_log(),
      limits = limits_x,
      expand = c(0, 0)
    ) +
    scale_y_log10(
      labels = scales::label_log(),
      limits = limits_y,
      expand = c(0, 0)
    ) +
    annotation_logticks(
      outside = T,
      color = lines_color,
      short = unit(0.04, "cm"),
      mid = unit(0.06, "cm"),
      long = unit(0.1, "cm"),
      linewidth = linewidth
    ) +
    theme_sags() +
    theme(
      panel.border = element_rect(color = lines_color, linewidth = linewidth),
      axis.ticks = element_blank()
    ) +
    coord_fixed(clip = "off")

  return(p_cytogram)
}

plot_cytogram_hex <- function(fcs_df,
                              xcol = "PE",
                              ycol = "PECY5",
                              limits_x = c(1, 1e4),
                              limits_y = c(1, 1e4),
                              nbins = 100) {

  lines_color <- scales::col_mix("black", "white", .2) # default for theme_bw
  linewidth <- 0.3

  p_cytogram_hex <-
    fcs_df |>
    ggplot(aes(x = !!sym(xcol), y = !!sym(ycol))) +
    geom_hex(bins = nbins) +
    scale_x_log10(
      labels = scales::label_log(),
      limits = limits_x,
      expand = c(0, 0)
    ) +
    scale_y_log10(
      labels = scales::label_log(),
      limits = limits_y,
      expand = c(0, 0)
    ) +
    annotation_logticks(
      outside = T,
      color = lines_color,
      short = unit(0.04, "cm"),
      mid = unit(0.06, "cm"),
      long = unit(0.1, "cm"),
      linewidth = linewidth
    ) +
    theme_sags() +
    theme(
      panel.border = element_rect(color = lines_color, linewidth = linewidth),
      axis.ticks = element_blank()
    ) +
    scale_fill_gradientn(colours = viridis(option = "turbo", n = 11), trans = "sqrt") + # taken from ggcyto package
    coord_fixed(clip = "off") +
    guides(fill = "none")

  return(p_cytogram_hex)
}

# Functions for amplicon data ---------------------------------------------

fasta_to_df <- function(fasta, name_col = "name", seq_col = "sequence") {

  require(Biostrings) |> suppressMessages()
  
  tibble(
    !!name_col := names(fasta),
    !!seq_col := as.character(fasta)
  )
}

remove_empty_taxa <- function(physeq) {
  
  require(phyloseq)
  prune_taxa(x = physeq, taxa = taxa_sums(physeq) > 0)

}

remove_empty_samples <- function(physeq) {
  prune_samples(x = physeq, samples = sample_sums(physeq) > 0)
}

factor_envplot <- function(df) {
  df %>%
    mutate(envplot = factor(envplot, levels = c(
      "marine_water", "marine_sediment",
      "freshwater", "freshwater_sediment", "soil"
    )))
}

envplot_colors <-
  set_names(
    c(
      "royalblue3", "#00A04B",
      "#FFB400", "#FF5A5F", "#7B0051"
    ),
    nm = c(
      "marine_water", "marine_sediment",
      "freshwater", "freshwater_sediment", "soil"
    )
  )

counts_to_percent <- function(physeq, total_col) {
  # transform counts to percentage but using a total defined in sample_data

  otu_tab <-
    as.matrix(otu_table(physeq))

  totals <- sample_data(physeq)[[total_col]]

  if (identical(rownames(sample_data(physeq)), colnames(otu_tab))) {
    new_otu_tab <-
      sweep(100 * otu_tab, 2, totals, `/`)

    new_physeq <- physeq

    otu_table(new_physeq) <- otu_table(new_otu_tab, taxa_are_rows = T)

    return(new_physeq)
  } else {
    message("Sample names order does not match betwen OTU and metadata tables")
  }
}


# Functions for functional enrichment -------------------------------------

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


# Functions for genomic architectures -------------------------------------

pca_plotter <- function(df, cluster_col, loadings = F, point_size = 3, text_size = 3, fill_points, hulls = F, fill_hulls) {
  df <-
    df |>
    dplyr::rename(cluster = all_of(cluster_col)) |>
    arrange(cluster) |>
    mutate(
      cluster = as.character(cluster),
      cluster = fct_inorder(cluster)
    )

  arrow_scale <- 2.5

  p_pca <-
    df |>
    ggplot(aes(x = PC1, y = PC2))

  if (hulls){
    if (str_detect(cluster_col,'^k')){
      p_pca <- 
        p_pca +
        geom_mark_hull(
          aes(fill = cluster),
          concavity = 3, 
          expand = 0.018, 
          radius = unit(3, "mm"), 
          color = NA, 
          alpha = 0.2
        )
      } else {
        p_pca <- 
          p_pca +
          geom_mark_hull(
            aes(fill = k5),
            concavity = 3, 
            expand = 0.018, 
            radius = unit(3, "mm"), 
            color = NA, 
            alpha = 0.2
          )
      }
    
    p_pca <- 
      p_pca +
      scale_fill_manual(values = fill_hulls) +
      guides(fill = 'none') +
      new_scale_fill()
  }
  
  p_pca <- 
    p_pca +
    geom_point(aes(fill = cluster), size = point_size, color = "gray20", stroke = 0.2, shape = 21) +
    labs(
      x = paste0("PC1 (", pc_explained[["PC1"]], "%)"),
      y = paste0("PC2 (", pc_explained[["PC2"]], "%)")
    ) +
    theme_sags() +
    scale_fill_manual(values = fill_points) +
    guides(fill = guide_legend(position = "top"))

  loadings_color <- "gray20"

  if (loadings) {
    p_pca <-
      p_pca +
      geom_segment(
        data = pca_loadings,
        aes(x = 0, y = 0, xend = PC1 * arrow_scale, yend = PC2 * arrow_scale),
        arrow = arrow(length = unit(0.2, "cm")), color = loadings_color, linewidth = 0.4
      ) +
      geom_richtext(
        data = pca_loadings,
        aes(x = PC1 * arrow_scale * 1.15, y = PC2 * arrow_scale * 1.15, label = paste0("**", region, "**"), hjust = hjust),
        color = loadings_color,
        fill = NA, label.color = NA,
        size = text_size
      )
  }
  
  return(p_pca)
}

summary_architecure_plotter_cluster <- function(stats, cluster_col = "k5", plot_spacer_length = -.097) {
  cluster_colors <-
    set_names(
      c("#4dbbd5ff", "#e64b35", "#00a087", "#3c5488", "#f39b7f"),
      as.character(1:5)
    )

  df <-
    stats |>
    select(sag_id, region, perc, cluster = all_of(cluster_col)) |>
    mutate(cluster = as.character(cluster))

  genome_length_df <-
    stats |>
    select(sag_id, cluster = all_of(cluster_col), `Genome size`) |>
    distinct() |>
    mutate(
      region = "Genome size",
      cluster = as.character(cluster)
    )

  p_genome_length <-
    genome_length_df |>
    ggplot(aes(y = `Genome size`, x = as.character(cluster))) +
    geom_point(
      position = position_jitter(width = 0.2, height = 0, seed = 123),
      aes(fill = cluster), shape = 21, color = "gray20", stroke = 0.2
    ) +
    geom_boxplot(aes(fill = cluster), color = "gray20", linewidth = 0.2, alpha = 0.7, outlier.shape = NA) +
    ggh4x::facet_grid2(region ~ ., scales = "free_y") +
    labs(y = "Mbp", x = "") +
    guides(fill = "none") +
    theme_sags() +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank()
    ) +
    scale_fill_manual(values = cluster_colors)

  p_stats_summmary <-
    df |>
    ggplot(aes(y = perc, x = as.character(cluster))) +
    geom_point(
      position = position_jitter(width = 0.2, height = 0, seed = 123),
      aes(fill = cluster), shape = 21, color = "gray20", stroke = 0.2
    ) +
    geom_boxplot(aes(fill = cluster), color = "gray20", linewidth = 0.2, alpha = 0.7, outlier.shape = NA) +
    ggh4x::facet_grid2(region ~ ., scales = "free_y") +
    labs(y = "% of genome", x = "Cluster") +
    theme_sags() +
    guides(fill = "none") +
    scale_fill_manual(values = cluster_colors)

  p_summary_composite <-
    p_genome_length /
      plot_spacer() /
      p_stats_summmary +
      plot_layout(heights = c(0.25, plot_spacer_length, .75)) &
      theme(strip.text = element_text(size = 8))

  return(p_summary_composite)
}

# Functions for SAG stats -------------------------------------------------

stats_plotter <- function(df, stat, xlab = "", ylab = "") {
  
  data_all <-
    df |>
    filter(name == stat)

  if (str_detect(stat, "N50")) {
    data_all <-
      data_all |>
      filter(value <= 60)
  }

  data_coassembly <-
    data_all |>
    filter(Coassembly == T)

  data_single <-
    data_all |>
    filter(Coassembly == F)

  point_size <- 1.5

  p_stats <-
    ggplot(data = data_all, aes(x = Fraction, y = value)) +
    geom_point(
      data = data_single, 
      aes(fill = Fraction), 
      shape = 21, 
      alpha = 1, 
      position = position_jitter(width = 0.2, height = 0, seed = 123),
      size = point_size, 
      stroke = 0.2
      ) +
    geom_point(
      stroke = 0.2, 
      data = data_coassembly, 
      color = "black", 
      fill = "white", 
      shape = 21, 
      position = position_jitter(width = 0.2, height = 0, seed = 123),
      size = point_size
      ) +
    geom_boxplot(aes(fill = Fraction), outlier.shape = NA, alpha = 0.7, size = 0.4) +
    labs(x = "", y = "") +
    theme_bw() +
    facet_wrap(~name) +
    theme_sags() +
    guides(color = "none", fill = guide_legend(title = NULL, nrow = 1)) +
    scale_fill_manual(values = c("nano-PP" = "turquoise3", "pico-PP" = "seagreen", "pico-HP" = "goldenrod1", "nano-HP" = "indianred"))
}

# Functions for trees -----------------------------------------------------

get_node_group_of_single_tip <- function(tree, group){
  
  as_tibble(tree) |> 
    filter(str_detect(label, group)) |> 
    pull(node)
  
}
