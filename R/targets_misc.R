################################################################################
#' List fastq files
#' @description
#' `r lifecycle::badge("maturing")`
#'
#' @param path path to files (required)
#' @param paired_end do you have paired_end files? (default TRUE)
#' @param pattern a pattern to filter files (passed on to list.files function).
#' @param pattern_R1 a pattern to filter R1 files (default "_R1_")
#' @param pattern_R2 a pattern to filter R2 files (default "_R2_")
#' @param nb_files the number of fastq files to list (default FALSE)
#'
#' @return a list of one (single end) or two (paired end) list of files
#'   files are sorted by names (default behavior of `list.files()`)
#' @export
#'
#' @examples
#' list_fastq_files("inst/extdata")
#' list_fastq_files("inst/extdata", paired_end = FALSE, pattern_R1 = "")
#'
#' @author Adrien Taudière

list_fastq_files <-
  function(path,
           paired_end = TRUE,
           pattern = "fastq",
           pattern_R1 = "_R1_",
           pattern_R2 = "_R2_",
           nb_files = Inf) {
    list_files <- list.files(path, pattern = pattern, full.names = TRUE)
    if (paired_end) {
      fnfs <- sort(list_files[grepl(list_files, pattern = pattern_R1)])
      fnrs <-
        sort(list_files[grepl(list_files, pattern = pattern_R2)])
      if (is.finite(nb_files)) {
        fnfs <- fnfs[1:nb_files]
        fnrs <- fnrs[1:nb_files]
      }
      return(list("fnfs" = fnfs, "fnrs" = fnrs))
    } else {
      fnfs <- sort(list_files[grepl(list_files, pattern = pattern_R1)])
      if (is.finite(nb_files)) {
        fnfs <- fnfs[1:nb_files]
      }
      return(list("fnfs" = fnfs))
    }
  }
################################################################################


################################################################################
#' Rename samples of an otu_table
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams clean_pq
#' @param names_of_samples (required) The new names of the samples
#'
#' @return the matrix with new colnames (or rownames if `taxa_are_rows` is true)
#'
#' @export
#' @md
#'
#' @author Adrien Taudière
#'
#' @examples
#' data(data_fungi)
#' rename_samples_otu_table(data_fungi, as.character(1:nsamples(data_fungi)))
#'
rename_samples_otu_table <- function(physeq, names_of_samples) {
  otu_tab <- physeq@otu_table
  tax_in_row <- taxa_are_rows(physeq)
  if (tax_in_row) {
    if (length(names_of_samples) == dim(otu_tab)[2]) {
      colnames(otu_tab) <- names_of_samples
      return(otu_tab)
    } else {
      stop("names_of_samples must have a length equal to the number of samples")
    }
  } else {
    if (length(names_of_samples) == dim(otu_tab)[1]) {
      rownames(otu_tab) <- names_of_samples
      return(otu_tab)
    } else {
      stop("names_of_samples must have a length equal to the number of samples")
    }
  }
}
################################################################################

# ( pattern = "fastq.gz", pattern_R1 = "_R1", pattern_R2 = "_R2")



################################################################################
# WORK IN PROGRESS
#' Remove primers using cutadapt Work In Progress
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return a list of commande but in The future, will
#'   run the commandes using system
#'
#' @author Adrien Taudière
#'

# cutadapt_remove_primers <- function(
#    path,
#    output_folder = "wo_primers",
#    primer_fw = NULL,
#    primer_rev = NULL,
#    nproc = 1,
#    ...) {
#  cmd <- list()
#
#  if (is.null(primer_rev)) {
#    lff <- list_fastq_files(path, paired_end = FALSE, ...)
#    for (f in lff$fnfs) {
#      cmd[[i]] <- paste0(
#        "source ~/miniconda3/etc/profile.d/conda.sh &&
#    conda activate cutadaptenv && ",
#        "cutadapt --cores=",
#        nproc,
#        " --discard-untrimmed -g '", primer_fw, "' -o ", output_folder,
#        "/", basename(f), " ", f
#      )
#    }
#  } else {
#    lff <- list_fastq_files(path, paired_end = TRUE, ...)
#
#    primer_fw_RC <- dada2:::rc(primer_fw)
#    primer_rev_RC <- dada2:::rc(primer_rev)
#    for (f in lff$fnfs) {
#      cmd[[i]] <- paste0(
#        "source ~/miniconda3/etc/profile.d/conda.sh &&
#    conda activate cutadaptenv && ",
#        "cutadapt -n 2 --cores=",
#        nproc,
#        " --discard-untrimmed -g '", primer_fw,
#        "' -G '", primer_rev,
#        "' -a '", primer_rev_RC,
#        "' -A '", primer_fw_RC,
#        "' -o ", output_folder,
#        "/", basename(f), " -p ", output_folder,
#        "/", gsub("R1", "R2", basename(f)), " ", f, " ",
#        gsub("R1", "R2", f)
#      )
#    }
#  }
#
#  return(cmd)
#  # lapply(cmd, system)
# }
################################################################################
