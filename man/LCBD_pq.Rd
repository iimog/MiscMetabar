% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/beta_div_test.R
\name{LCBD_pq}
\alias{LCBD_pq}
\title{Compute and test local contributions to beta diversity (LCBD) of samples}
\usage{
LCBD_pq(physeq, p_adjust_method = "BH", ...)
}
\arguments{
\item{physeq}{(required): a \code{\link{phyloseq-class}} object obtained
using the \code{phyloseq} package.}

\item{p_adjust_method}{(chr, default "BH"): the method used to adjust p-value}

\item{...}{Others arguments passed on to \code{\link[adespatial:beta.div]{adespatial::beta.div()}} function}
}
\value{
An object of class \code{beta.div} see \code{\link[adespatial:beta.div]{adespatial::beta.div()}} function
for more information
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#experimental}{\figure{lifecycle-experimental.svg}{options: alt='[Experimental]'}}}{\strong{[Experimental]}}

A wrapper for the \code{\link[adespatial:beta.div]{adespatial::beta.div()}} function in the case of \code{physeq}
object.
}
\examples{
LCBD_pq(data_fungi, nperm=100)
LCBD_pq(data_fungi, nperm=100, method = "jaccard")
}
\seealso{
\link{plot_LCBD_pq}, \code{\link[adespatial:beta.div]{adespatial::beta.div()}}
}
