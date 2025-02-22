#' @title Performs graph-based permutation tests on phyloseq object
#' @description
#' `r lifecycle::badge("maturing")`
#'
#' A wrapper of [phyloseqGraphTest::graph_perm_test()] for quick plot with
#' important statistics

#' @inheritParams clean_pq
#' @param fact (required) Name of the factor to cluster samples by modalities.
#'   Need to be in \code{physeq@sam_data}. This should be a factor
#'   with two or more levels.
#' @param merge_sample_by a vector to determine
#'   which samples to merge using the
#'   \code{\link[speedyseq]{merge_samples2}} function.
#'   Need to be in \code{physeq@sam_data}
#' @param nperm (int) The number of permutations to perform.
#' @param return_plot (logical) Do we return only the result
#'   of the test or do we plot the result?
#' @param title The title of the Graph.
#' @param na_remove (logical, default FALSE) If set to TRUE, remove samples with
#'   NA in the variables set in formula.
#' @param ... other params for be passed on to
#'   [phyloseqGraphTest::graph_perm_test()] function
#'
#' @examples
#' data(enterotype)
#' graph_test_pq(enterotype, fact = "SeqTech")
#' graph_test_pq(enterotype, fact = "Enterotype", na_remove = TRUE)
#' @author Adrien Taudière
#'
#' @return A \code{\link{ggplot}}2 plot with a subtitle indicating the pvalue
#' and the number of permutations
#'
#' @export

graph_test_pq <- function(physeq,
                          fact,
                          merge_sample_by = NULL,
                          nperm = 999,
                          return_plot = TRUE,
                          title = "Graph Test",
                          na_remove = FALSE,
                          ...) {
  verify_pq(physeq)

  if (!is.null(merge_sample_by)) {
    physeq <- speedyseq::merge_samples2(physeq, merge_sample_by)
    physeq <- clean_pq(physeq)
  }

  if (na_remove) {
    new_physeq <-
      subset_samples_pq(physeq,!is.na(physeq@sam_data[[fact]]))
    if (nsamples(physeq) - nsamples(new_physeq) > 0) {
      message(
        paste0(
          nsamples(physeq) - nsamples(new_physeq),
          " were discarded due to NA in variables present in formula."
        )
      )
    }
    physeq <- new_physeq
  }

  res_graph_test <- phyloseqGraphTest::graph_perm_test(physeq,
                                                       sampletype = fact,
                                                       nperm = nperm,
                                                       ...)
  if (!return_plot) {
    return(res_graph_test)
  } else {
    p <- phyloseqGraphTest::plot_test_network(res_graph_test) +
      labs(
        title = title,
        subtitle = paste(
          "pvalue = ",
          res_graph_test$pval,
          "(",
          length(res_graph_test$perm),
          " permutations)"
        )
      )
    return(p)
  }
}


#' @title Permanova on a phyloseq object
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A wrapper for the [vegan::adonis2()] function in the case of `physeq` object.
#' @inheritParams clean_pq
#' @param formula (required) the right part of a formula for [vegan::adonis2()].
#'   Variables must be present in the `physeq@sam_data` slot.
#' @param dist_method (default "bray") the distance used. See
#'   [phyloseq::distance()] for all available distances or run
#'   [phyloseq::distanceMethodList()].
#'   For aitchison and robust.aitchison distance, [vegan::vegdist()]
#'   function is directly used.
#' @param merge_sample_by a vector to determine
#'   which samples to merge using the [speedyseq::merge_samples2()]
#'   function. Need to be in `physeq@sam_data`
#' @param na_remove (logical, default FALSE) If set to TRUE, remove samples with
#'   NA in the variables set in formula.
#' @param correction_for_sample_size (logical, default FALSE) If set to TRUE, the
#'   sample size (number of sequences by samples) is add to formula in the form
#'   `y~Library_Size + Biological_Effect` following recommendation of
#'   [Weiss et al. 2017](https://doi.org/10.1186/s40168-017-0237-y).
#'   `correction_for_sample_size` overcome `rarefy_nb_seqs` if both are TRUE.
#' @param rarefy_nb_seqs (logical, default FALSE) Rarefy each sample
#'   (before merging if merge_sample_by is set) using `phyloseq::rarefy_even_depth()`.
#'   if `correction_for_sample_size` is TRUE, rarefy_nb_seqs will have no effect.
#' @param ... Other arguments passed on to [vegan::adonis2()] function.
#' @return The function returns an anova.cca result object with a
#'   new column for partial R^2. See help of [vegan::adonis2()] for more information.
#' @examples
#' data(enterotype)
#' adonis_pq(enterotype, "SeqTech*Enterotype", na_remove = TRUE)
#' adonis_pq(enterotype, "SeqTech")
#' adonis_pq(enterotype, "SeqTech", dist_method = "jaccard")
#' adonis_pq(enterotype, "SeqTech", dist_method = "robust.aitchison")
#' @export
#' @author Adrien Taudière

adonis_pq <- function(physeq,
                      formula,
                      dist_method = "bray",
                      merge_sample_by = NULL,
                      na_remove = FALSE,
                      correction_for_sample_size = FALSE,
                      rarefy_nb_seqs = FALSE,
                      ...) {
  physeq <- clean_pq(
    physeq,
    force_taxa_as_columns = TRUE,
    remove_empty_samples = TRUE,
    remove_empty_taxa = FALSE,
    clean_samples_names = FALSE,
    silent = TRUE
  )

  if (dist_method %in% c("aitchison", "robust.aitchison")) {
    phy_dist <-
      paste0('vegan::vegdist(as.matrix(physeq@otu_table), method="',
             dist_method,
             '")')
  } else {
    phy_dist <-
      paste0('phyloseq:::distance(physeq, method="', dist_method, '")')
  }

  .formula <- stats::reformulate(formula, response = phy_dist)
  termf <- stats::terms(.formula)
  term_lab <- attr(termf, "term.labels")[attr(termf, "order") == 1]

  verify_pq(physeq, ...)

  if (na_remove) {
    new_physeq <- physeq
    for (tl in term_lab) {
      print(tl)
      new_physeq <-
        subset_samples_pq(new_physeq,!is.na(physeq@sam_data[[tl]]))
    }
    if (nsamples(physeq) - nsamples(new_physeq) > 0) {
      message(
        paste0(
          nsamples(physeq) - nsamples(new_physeq),
          " were discarded due to NA in variables present in formula."
        )
      )
    }
    physeq <- new_physeq
  }

  if (!is.null(merge_sample_by)) {
    physeq <- speedyseq::merge_samples2(physeq, merge_sample_by)
    physeq <- clean_pq(physeq)
  }

  if (correction_for_sample_size) {
    formula <- paste0("sample_size+", formula)
    .formula <- stats::reformulate(formula, response = phy_dist)
  } else if (rarefy_nb_seqs) {
    physeq <- rarefy_even_depth(physeq)
    physeq <- clean_pq(physeq)
  }

  verify_pq(physeq)
  metadata <- as(sample_data(physeq), "data.frame")
  if (correction_for_sample_size) {
    metadata$sample_size <- sample_sums(physeq)
  }

  res_ado <- vegan::adonis2(.formula, data = metadata, ...)
  return(res_ado)
}



#' @title Compute and test local contributions to beta diversity (LCBD) of samples
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A wrapper for the [adespatial::beta.div()] function in the case of `physeq`
#'   object.
#' @inheritParams clean_pq
#'
#' @param p_adjust_method (chr, default "BH"): the method used to adjust p-value
#' @param ... Others arguments passed on to [adespatial::beta.div()] function
#'
#' @return An object of class `beta.div` see [adespatial::beta.div()] function
#'   for more information
#' @export
#' @seealso [plot_LCBD_pq], [adespatial::beta.div()]
#' @examples
#' LCBD_pq(data_fungi, nperm=100)
#' LCBD_pq(data_fungi, nperm=100, method = "jaccard")
LCBD_pq <- function(physeq,
                    p_adjust_method =  "BH",
                    ...) {
  physeq <- clean_pq(
    physeq,
    force_taxa_as_columns = TRUE,
    remove_empty_samples = TRUE,
    remove_empty_taxa = FALSE,
    clean_samples_names = FALSE,
    silent = TRUE
  )

  mat <- as.matrix(unclass(physeq@otu_table))
  resBeta <- beta.div(mat, adj = FALSE, ...)

  resBeta$p.adj <-
    p.adjust(resBeta$p.LCBD, method = p_adjust_method)
  return(resBeta)
}


#' @title Plot and test local contributions to beta diversity (LCBD) of samples
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A wrapper for the [adespatial::beta.div()] function in the case of `physeq`
#'   object.
#' @inheritParams clean_pq
#'
#' @param p_adjust_method (chr, default "BH"): the method used to adjust p-value
#' @param pval (int, default 0.05): the value to determine the significance of
#'   LCBD
#' @param sam_variables A vector of variables names present in the `sam_data`
#'   slot to plot alongside the LCBD value
#' @param only_plot_significant (logical, default TRUE) Do we plot all LCBD
#'   values or only the significant ones
#' @param ... Others arguments passed on to [adespatial::beta.div()] function
#'
#' @return A ggplot object build with the package patchwork
#' @export
#' @seealso [LCBD_pq], [adespatial::beta.div()]
#'
#' @examples
#' plot_LCBD_pq(data_fungi, nperm=100, only_plot_significant = FALSE, pval = 0.2)
#' plot_LCBD_pq(data_fungi, nperm=100, only_plot_significant = TRUE, pval = 0.2)
#' plot_LCBD_pq(data_fungi, nperm=100, only_plot_significant = FALSE,
#'   sam_variables=c("Time", "Height"))
#' plot_LCBD_pq(data_fungi, nperm=100,  only_plot_significant = TRUE, pval = 0.2,
#'   sam_variables=c("Time", "Height", "Tree_name")) &
#'   theme(legend.key.size = unit(0.4, 'cm'),
#'         legend.text = element_text(size=10),
#'         axis.title.x = element_text(size=6))
#' @author Adrien Taudière
plot_LCBD_pq <- function(physeq,
                         p_adjust_method =  "BH",
                         pval =  0.05,
                         sam_variables = NULL,
                         only_plot_significant = TRUE,
                         ...) {
  resBeta <-  LCBD_pq(physeq,
                      p_adjust_method = p_adjust_method,
                      ...)

  sam_data <- data.frame(physeq@sam_data)

  if (sum(is.na(match(
    rownames(sam_data), names(resBeta$LCBD)
  ))) > 0) {
    warning("At least one sample was removed by the beta.div function")
    sam_data <-
      sam_data[rownames(sam_data) %in% names(resBeta$LCBD), ]
  }

  resLCBD <- tibble(
    "LCBD" = resBeta$LCBD,
    "p.LCBD" = resBeta$p.LCBD,
    "p.adj" = resBeta$p.adj,
    sam_data
  )

  if (only_plot_significant) {
    p_LCBD <-
      ggplot(filter(resLCBD, p.adj < pval), aes(x = LCBD, y = reorder(Sample_names,-LCBD, sum))) +
      geom_point(size = 4)
    if (is.null(sam_variables)) {
      return(p_LCBD)
    } else {
      p_heatmap <- list()
      for (i in 1:length(sam_variables)) {
        p_heatmap[[i]] <- ggplot(filter(resLCBD, p.adj < pval)) +
          geom_tile(inherit.aes = FALSE, aes(
            y = reorder(Sample_names,-LCBD, sum),
            x = i,
            fill = .data[[sam_variables[[i]]]]
          )) +
          theme_void() + theme(
            axis.title.x = element_text()
          ) +
          xlab(sam_variables[[i]])
      }

      p <-
        p_LCBD + patchwork::wrap_plots(p_heatmap) + plot_layout(widths = c(3, 1) , guides =
                                                                  "collect")
      return(p)
    }
  } else {
    p_LCBD <-
      ggplot(resLCBD, aes(x = LCBD, y = reorder(Sample_names,-LCBD, sum))) +
      geom_point(aes(color = p.adj < pval))
    if (is.null(sam_variables)) {
      return(p_LCBD)
    } else {
      p_heatmap <- list()
      for (i in 1:length(sam_variables)) {
        p_heatmap[[i]] <- ggplot(resLCBD) +
          geom_tile(inherit.aes = FALSE, aes(
            y = reorder(Sample_names,-LCBD, sum),
            x = i,
            fill = .data[[sam_variables[[i]]]]
          )) +
          theme_void() + theme(
            axis.title.x = element_text()
          ) +
          xlab(sam_variables[[i]])
      }

      p <-
        p_LCBD + patchwork::wrap_plots(p_heatmap) + plot_layout(widths = c(3, 1) , guides =
                                                                  "collect")
      return(p)
    }
  }


}


#' @title Test and plot multipatt result
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A wrapper for the [indicspecies::multipatt()] function in the case of `physeq`
#'   object.
#' @inheritParams clean_pq
#' @param fact (required) Name of the factor in `physeq@sam_data` used to plot
#'    different lines
#' @param p_adjust_method (chr, default "BH"): the method used to adjust p-value
#' @param pval (int, default 0.05): the value to determine the significance of
#'   LCBD
#' @param control see `?indicspecies::multipatt()`
#' @param ... Others arguments passed on to [indicspecies::multipatt()] function
#'
#' @return A ggplot object
#' @export
#' @examples 
#' multipatt_pq(subset_samples(data_fungi, !is.na(Time)), fact="Time")
#' multipatt_pq(subset_samples(data_fungi, !is.na(Time)), fact="Time",
#'    max.order = 1, control = how(nperm=9999))
#' @author Adrien Taudière

multipatt_pq <- function(physeq,
fact,
p_adjust_method =  "BH",
pval = 0.05,
control = how(nperm = 999),
...){

res <-
  indicspecies::multipatt(as.matrix(physeq@otu_table),
            physeq@sam_data[[fact]],
            control = control,
            ...)
            
res_df <- res$sign
res_df$p.adj <- p.adjust(res_df$p.value, method = p_adjust_method)
res_df$ASV_names <- rownames(res_df)
res_df_signif <-
  res_df %>% filter(p.adj < pval) %>% tidyr::pivot_longer(cols = starts_with("s."))

p <- ggplot(res_df_signif,
       aes(
         x = ASV_names,
         y = name,
         size = 2 * value,
         color = stat
       )) + geom_point() + theme(axis.text.x = element_text(
         angle = 90,
         vjust = 0.5,
         hjust = 1
       ))
return(p)
}