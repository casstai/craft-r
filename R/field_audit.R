#' Rationale audit (F step of CRAFT)
#'
#' Given a data frame of annotations from two LLMs (with confidence and
#' rationale columns), surface the rows that need human review:
#' disagreements on the final label, and low-confidence agreements
#' where the threshold is debatable.
#'
#' @param annotations Data frame with at least these columns:
#'   \code{id}, \code{text}, \code{label_a}, \code{label_b},
#'   \code{confidence_a}, \code{confidence_b}, optionally
#'   \code{rationale_a}, \code{rationale_b}.
#' @param confidence_threshold Numeric; rows where either confidence is
#'   below this value are flagged as \code{"low_conf_agreement"} when
#'   the labels match, or kept in \code{"disagreement"} when they
#'   differ.
#' @param low_threshold Below this value, agreements are treated as
#'   "agreement on uncertainty" rather than usable labels.
#'
#' @return A data frame with an added \code{audit_status} column
#'   (one of \code{"agreement"}, \code{"low_conf_agreement"},
#'   \code{"uncertainty_agreement"}, \code{"disagreement"}).
#'
#' @examples
#' \dontrun{
#'   a <- audit(annotations,
#'              confidence_threshold = 0.6,
#'              low_threshold = 0.31)
#'   table(a$audit_status)
#' }
#'
#' @export
audit <- function(annotations,
                            confidence_threshold = 0.6,
                            low_threshold = 0.31) {
  required <- c("id", "label_a", "label_b", "confidence_a", "confidence_b")
  missing  <- setdiff(required, names(annotations))
  if (length(missing)) {
    stop("`annotations` is missing required column(s): ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  out <- annotations
  out$audit_status <- with(
    out,
    ifelse(label_a != label_b, "disagreement",
      ifelse(confidence_a < low_threshold & confidence_b < low_threshold,
             "uncertainty_agreement",
        ifelse(confidence_a < confidence_threshold |
               confidence_b < confidence_threshold,
               "low_conf_agreement",
               "agreement")))
  )
  out
}


#' Summarize cases needing adjudication
#'
#' Returns just the rows of \code{audit} that require human review,
#' optionally restricted to one \code{audit_status} category.
#'
#' @param audit A data frame produced by \code{\link{audit}}.
#' @param status Which status(es) to return. Default returns
#'   disagreements and low-confidence agreements.
#'
#' @return A subset of \code{audit}.
#'
#' @export
disagree <- function(audit,
                               status = c("disagreement", "low_conf_agreement")) {
  if (!"audit_status" %in% names(audit)) {
    stop("`audit` must contain an `audit_status` column (see `audit()`).",
         call. = FALSE)
  }
  audit[audit$audit_status %in% status, , drop = FALSE]
}


#' Sensitivity of label coverage to the confidence threshold
#'
#' Recomputes the audit categorization across a grid of confidence
#' thresholds so the researcher can see how many cases drop into
#' "low_conf_agreement" or "uncertainty" at each tau.
#'
#' @param annotations As in \code{\link{audit}}.
#' @param thresholds Numeric vector of confidence thresholds to scan
#'   (e.g. \code{c(0.5, 0.55, 0.6, 0.7)}).
#' @param low_threshold Passed to \code{\link{audit}}.
#'
#' @return A long data frame: one row per (threshold, audit_status)
#'   with column \code{n}.
#'
#' @export
tau_sens <- function(annotations,
                                  thresholds = c(0.5, 0.55, 0.6, 0.7),
                                  low_threshold = 0.31) {
  rows <- lapply(thresholds, function(t) {
    a <- audit(annotations,
                         confidence_threshold = t,
                         low_threshold = low_threshold)
    tab <- as.data.frame(table(audit_status = a$audit_status),
                         stringsAsFactors = FALSE)
    names(tab)[2] <- "n"
    tab$threshold <- t
    tab[, c("threshold", "audit_status", "n")]
  })
  do.call(rbind, rows)
}
