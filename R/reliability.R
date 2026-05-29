#' Inter-rater reliability (R step of CRAFT)
#'
#' Unified interface to common inter-rater reliability metrics, so the
#' researcher can pick a method appropriate to their data. The
#' \code{method} argument chooses among:
#'
#' \describe{
#'   \item{\code{"cohen"}}{Cohen's kappa. Two raters, nominal data. Wraps
#'     \code{irr::kappa2(weight = "unweighted")}.}
#'   \item{\code{"weighted"}}{Weighted Cohen's kappa. Two raters, ordinal
#'     data. Wraps \code{irr::kappa2()} with \code{weight = "equal"} (linear)
#'     or \code{"squared"} (quadratic) via the \code{weights} argument.}
#'   \item{\code{"fleiss"}}{Fleiss' kappa. More than two raters, nominal
#'     data. Wraps \code{irr::kappam.fleiss()}.}
#'   \item{\code{"kripp"}}{Krippendorff's alpha. Any number of raters,
#'     missing values allowed, any measurement level. Wraps
#'     \code{irr::kripp.alpha()} with \code{method} controlled by the
#'     \code{level} argument (\code{"nominal"}, \code{"ordinal"},
#'     \code{"interval"}, \code{"ratio"}).}
#'   \item{\code{"icc"}}{Intra-class correlation. Continuous ratings.
#'     Wraps \code{irr::icc()}. Use \code{type} and \code{model} arguments
#'     for the ICC form.}
#'   \item{\code{"agree"}}{Simple percent agreement. Wraps
#'     \code{irr::agree()}. Reported alongside other metrics; not a
#'     substitute for chance-corrected agreement.}
#' }
#'
#' All methods return a tidy one-row data frame with columns
#' \code{method}, \code{value}, \code{n_raters}, \code{n_items}, and any
#' method-specific fields (e.g., \code{p_value}, \code{ci_lower},
#' \code{ci_upper} when available).
#'
#' @param ratings A data frame or matrix where each column is a rater
#'   (annotator / model) and each row is an item. Missing values are
#'   permitted by \code{kripp.alpha} but not by the others.
#' @param method One of \code{"cohen"}, \code{"weighted"}, \code{"fleiss"},
#'   \code{"kripp"}, \code{"icc"}, \code{"agree"}. The default
#'   \code{"auto"} picks \code{"cohen"} for 2 raters + nominal data,
#'   \code{"weighted"} for 2 raters + ordinal data, \code{"fleiss"} for
#'   >2 raters + nominal data, \code{"kripp"} otherwise.
#' @param level Measurement level: \code{"nominal"}, \code{"ordinal"},
#'   \code{"interval"}, or \code{"ratio"}. Used by \code{"auto"},
#'   \code{"weighted"}, and \code{"kripp"}.
#' @param weights For \code{method = "weighted"}: either \code{"equal"}
#'   (linear) or \code{"squared"} (quadratic).
#' @param ... Passed to the underlying \code{irr} function (e.g.
#'   \code{type}, \code{model} for ICC).
#'
#' @return A one-row data frame.
#'
#' @examples
#' \dontrun{
#'   ratings <- data.frame(
#'     human  = c("sup", "opp", "sup", "non"),
#'     gpt5   = c("sup", "opp", "sup", "non"),
#'     gemini = c("sup", "opp", "non", "non")
#'   )
#'   reliab(ratings, method = "kripp", level = "nominal")
#'   reliab(ratings[, 1:2], method = "cohen")
#'   reliab(ratings, method = "fleiss")
#' }
#'
#' @export
reliab <- function(ratings,
                        method = c("auto", "cohen", "weighted", "fleiss",
                                   "kripp", "icc", "agree"),
                        level   = c("nominal", "ordinal", "interval", "ratio"),
                        weights = c("equal", "squared"),
                        ...) {
  method <- match.arg(method)
  level  <- match.arg(level)

  ratings <- as.data.frame(ratings)
  n_raters <- ncol(ratings)
  n_items  <- nrow(ratings)

  if (method == "auto") {
    method <- if (n_raters == 2 && level == "nominal") {
      "cohen"
    } else if (n_raters == 2 && level %in% c("ordinal", "interval", "ratio")) {
      "weighted"
    } else if (n_raters >= 3 && level == "nominal") {
      "fleiss"
    } else {
      "kripp"
    }
  }

  out <- switch(
    method,
    cohen    = .reliability_cohen(ratings, ...),
    weighted = .reliability_weighted(ratings, weights = match.arg(weights), ...),
    fleiss   = .reliability_fleiss(ratings, ...),
    kripp    = .reliability_kripp(ratings, level = level, ...),
    icc      = .reliability_icc(ratings, ...),
    agree    = .reliability_agree(ratings, ...)
  )

  out$n_raters <- n_raters
  out$n_items  <- n_items
  out[, union(c("method", "value", "n_raters", "n_items"), names(out)), drop = FALSE]
}


# ----- internal dispatchers -----

.reliability_cohen <- function(ratings, ...) {
  if (ncol(ratings) != 2) {
    stop("Cohen's kappa requires exactly 2 raters; got ", ncol(ratings),
         ". Use method = 'fleiss' or 'kripp' for >2 raters.", call. = FALSE)
  }
  k <- irr::kappa2(ratings, weight = "unweighted")
  data.frame(method  = "cohen",
             value   = k$value,
             p_value = k$p.value,
             stringsAsFactors = FALSE)
}

.reliability_weighted <- function(ratings, weights, ...) {
  if (ncol(ratings) != 2) {
    stop("Weighted kappa requires exactly 2 raters; got ", ncol(ratings),
         ".", call. = FALSE)
  }
  k <- irr::kappa2(ratings, weight = weights)
  data.frame(method  = paste0("weighted_kappa_", weights),
             value   = k$value,
             p_value = k$p.value,
             stringsAsFactors = FALSE)
}

.reliability_fleiss <- function(ratings, ...) {
  if (ncol(ratings) < 3) {
    stop("Fleiss' kappa requires >= 3 raters; got ", ncol(ratings),
         ". Use method = 'cohen' for 2 raters.", call. = FALSE)
  }
  k <- irr::kappam.fleiss(ratings)
  data.frame(method  = "fleiss",
             value   = k$value,
             p_value = k$p.value,
             stringsAsFactors = FALSE)
}

.reliability_kripp <- function(ratings, level, ...) {
  # irr::kripp.alpha expects a numeric matrix with raters in rows.
  # For nominal data, map character labels to integer codes so the
  # underlying as.numeric() coercion doesn't emit warnings.
  if (level == "nominal") {
    all_lvls <- unique(unlist(lapply(ratings, as.character)))
    coded <- lapply(ratings, function(col) match(as.character(col), all_lvls))
    mat <- t(do.call(cbind, coded))
  } else {
    mat <- t(as.matrix(sapply(ratings, as.numeric)))
  }
  a <- irr::kripp.alpha(mat, method = level)
  data.frame(method = paste0("krippendorff_alpha_", level),
             value  = a$value,
             stringsAsFactors = FALSE)
}

.reliability_icc <- function(ratings, ...) {
  ic <- irr::icc(ratings, ...)
  data.frame(method  = paste0("icc_", ic$type, "_", ic$model),
             value   = ic$value,
             p_value = ic$p.value,
             ci_lower = ic$lbound,
             ci_upper = ic$ubound,
             stringsAsFactors = FALSE)
}

.reliability_agree <- function(ratings, ...) {
  a <- irr::agree(ratings, ...)
  data.frame(method = "percent_agreement",
             value  = a$value / 100,
             stringsAsFactors = FALSE)
}


#' Pairwise reliability across all rater columns
#'
#' Convenience wrapper that computes \code{\link{reliab}} for every
#' pair of rater columns in \code{ratings} and returns a tidy long
#' data frame with one row per pair.
#'
#' @inheritParams reliab
#' @param order Optional character vector specifying the display order
#'   of rater names. Useful for plotting.
#'
#' @return A data frame with columns \code{RaterA}, \code{RaterB},
#'   \code{method}, \code{value}.
#'
#' @export
reliab_pairs <- function(ratings,
                                 method = "cohen",
                                 level  = "nominal",
                                 weights = "equal",
                                 order = NULL,
                                 ...) {
  coders <- colnames(ratings)
  if (is.null(coders)) coders <- paste0("rater", seq_len(ncol(ratings)))

  if (!is.null(order)) {
    missing <- setdiff(order, coders)
    if (length(missing)) {
      stop("`order` references rater names not in `ratings`: ",
           paste(missing, collapse = ", "), call. = FALSE)
    }
  }

  combos <- utils::combn(coders, 2, simplify = FALSE)
  rows <- lapply(combos, function(pair) {
    r <- reliab(ratings[, pair, drop = FALSE],
                method = method, level = level, weights = weights, ...)
    data.frame(RaterA = pair[1], RaterB = pair[2],
               method = r$method, value = r$value,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)

  if (!is.null(order)) {
    out$RaterA <- factor(out$RaterA, levels = order)
    out$RaterB <- factor(out$RaterB, levels = order)
  }
  out
}
