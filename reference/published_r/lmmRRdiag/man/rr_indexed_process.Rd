\name{rr_indexed_process}
\alias{rr_indexed_process}
\title{Indexed residual process}
\description{Returns the ordered indexed recursive-residual process \eqn{S_z(r)}. The logical column \code{block_end} marks the last residual of each block of tied index values.}
\usage{rr_indexed_process(w, index)}
\arguments{\item{w}{Numeric residual vector.} \item{index}{Ordering index.}}
\value{A data frame with columns index, w, r, S, and block_end.}
\keyword{models}
