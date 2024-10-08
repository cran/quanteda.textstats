% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/textstat_collocations.R
\name{textstat_collocations}
\alias{textstat_collocations}
\title{Identify and score multi-word expressions}
\usage{
textstat_collocations(
  x,
  method = "lambda",
  size = 2,
  min_count = 2,
  smoothing = 0.5,
  tolower = TRUE,
  ...
)
}
\arguments{
\item{x}{a character, \link[quanteda:corpus]{corpus}, or
\link[quanteda:tokens]{tokens} object whose collocations will be scored.  The
tokens object should include punctuation, and if any words have been
removed, these should have been removed with \code{padding = TRUE}. While
identifying collocations for tokens objects is supported, you will get
better results with character or corpus objects due to relatively imperfect
detection of sentence boundaries from texts already tokenized.}

\item{method}{association measure for detecting collocations. Currently this
is limited to \code{"lambda"}.  See Details.}

\item{size}{integer; the length of the collocations
to be scored}

\item{min_count}{numeric; minimum frequency of collocations that will be
scored}

\item{smoothing}{numeric; a smoothing parameter added to the observed counts
(default is 0.5)}

\item{tolower}{logical; if \code{TRUE}, form collocations as lower-cased
combinations}

\item{...}{additional arguments passed to \link[quanteda:tokens]{tokens()}}
}
\value{
\code{textstat_collocations} returns a data.frame of collocations and
their scores and statistics. This consists of the collocations, their
counts, length, and \eqn{\lambda} and \eqn{z} statistics.  When \code{size} is a
vector, then \code{count_nested} counts the lower-order collocations that occur
within a higher-order collocation (but this does not affect the
statistics).
}
\description{
Identify and score multi-word expressions, or adjacent fixed-length
collocations, from text.
}
\details{
Documents are grouped for the purposes of scoring, but collocations will not
span sentences. If \code{x} is a \link[quanteda:tokens]{tokens} object and some tokens
have been removed, this should be done using \verb{[tokens_remove](x, pattern, padding = TRUE)} so that counts will still be accurate, but the pads will
prevent those collocations from being scored.

The \code{lambda} computed for a size = \eqn{K}-word target multi-word expression
the coefficient for the  \eqn{K}-way interaction parameter in the saturated
log-linear model fitted to the counts of the terms forming the set of
eligible multi-word expressions. This is the same as the "lambda" computed in
Blaheta and Johnson's (2001), where all multi-word expressions are considered
(rather than just verbs, as in that paper). The \code{z} is the Wald
\eqn{z}-statistic computed as the quotient of \code{lambda} and the Wald statistic
for \code{lambda} as described below.

In detail:

Consider a \eqn{K}-word target expression \eqn{x}, and let \eqn{z} be any
\eqn{K}-word expression. Define a comparison function \eqn{c(x,z)=(j_{1},
\dots, j_{K})=c} such that the \eqn{k}th element of \eqn{c} is 1 if the
\eqn{k}th word in \eqn{z} is equal to the \eqn{k}th word in \eqn{x}, and 0
otherwise. Let \eqn{c_{i}=(j_{i1}, \dots, j_{iK})}, \eqn{i=1, \dots,
2^{K}=M}, be the possible values of \eqn{c(x,z)}, with \eqn{c_{M}=(1,1,
\dots, 1)}. Consider the set of \eqn{c(x,z_{r})} across all expressions
\eqn{z_{r}} in a corpus of text, and let \eqn{n_{i}}, for \eqn{i=1,\dots,M},
denote the number of the \eqn{c(x,z_{r})} which equal \eqn{c_{i}}, plus the
smoothing constant \code{smoothing}. The \eqn{n_{i}} are the counts in a
\eqn{2^{K}} contingency table whose dimensions are defined by the
\eqn{c_{i}}.

\eqn{\lambda}: The \eqn{K}-way interaction parameter in the saturated
loglinear model fitted to the \eqn{n_{i}}. It can be calculated as

\deqn{\lambda  = \sum_{i=1}^{M} (-1)^{K-b_{i}} * log n_{i}}

where \eqn{b_{i}} is the number of the elements of \eqn{c_{i}} which are
equal to 1.

Wald test \eqn{z}-statistic \eqn{z} is calculated as:

\deqn{z = \frac{\lambda}{[\sum_{i=1}^{M} n_{i}^{-1}]^{(1/2)}}}
}
\examples{
library("quanteda")
corp <- data_corpus_inaugural[1:2]
head(cols <- textstat_collocations(corp, size = 2, min_count = 2), 10)
head(cols <- textstat_collocations(corp, size = 3, min_count = 2), 10)

# extracting multi-part proper nouns (capitalized terms)
toks1 <- tokens(data_corpus_inaugural)
toks2 <- tokens_remove(toks1, pattern = stopwords("english"), padding = TRUE)
toks3 <- tokens_select(toks2, pattern = "^([A-Z][a-z\\\\-]{2,})", valuetype = "regex",
                       case_insensitive = FALSE, padding = TRUE)
tstat <- textstat_collocations(toks3, size = 3, tolower = FALSE)
head(tstat, 10)

# vectorized size
txt <- c(". . . . a b c . . a b c . . . c d e",
         "a b . . a b . . a b . . a b . a b",
         "b c d . . b c . b c . . . b c")
textstat_collocations(txt, size = 2:3)

# compounding tokens from collocations
toks <- tokens("This is the European Union.")
colls <- tokens("The new European Union is not the old European Union.") \%>\%
    textstat_collocations(size = 2, min_count = 1, tolower = FALSE)
colls
tokens_compound(toks, colls, case_insensitive = FALSE)

#' # from a collocations object
(coll <- textstat_collocations(tokens("a b c a b d e b d a b")))
phrase(coll)
}
\references{
Blaheta, D. & Johnson, M. (2001). \href{http://web.science.mq.edu.au/~mjohnson/papers/2001/dpb-colloc01.pdf}{Unsupervised learning of multi-word verbs}.
Presented at the ACLEACL Workshop on the Computational Extraction, Analysis
and Exploitation of Collocations.
}
\author{
Kenneth Benoit, Jouni Kuha, Haiyan Wang, and Kohei Watanabe
}
\keyword{collocations}
\keyword{textstat}
