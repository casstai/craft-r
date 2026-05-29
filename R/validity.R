#' Validity metrics against a gold standard
#'
#' Computes common validity metrics for categorical predictions against
#' a gold-standard reference. Returns a tidy one-row data frame so it
#' composes naturally with \code{\link{reliab}} via
#' \code{\link{dual}}.
#'
#' Supported metrics (researcher picks any subset via \code{metrics =}):
#' \describe{
#'   \item{\code{precision}}{Macro-averaged precision (unweighted mean
#'     across classes).}
#'   \item{\code{recall}}{Macro-averaged recall.}
#'   \item{\code{f1_macro}}{Macro-averaged F1 (treats each class equally;
#'     useful when class balance is roughly equal or when minority-class
#'     performance matters).}
#'   \item{\code{f1_weighted}}{Class-frequency-weighted F1 (weights each
#'     class's F1 by its support; closer to overall accuracy when classes
#'     are imbalanced).}
#'   \item{\code{accuracy}}{Overall accuracy.}
#'   \item{\code{balanced_accuracy}}{Mean of per-class recall.}
#'   \item{\code{mcc}}{Matthews correlation coefficient, generalized to
#'     multi-class.}
#' }
#'
#' @param gold A vector of gold-standard labels.
#' @param pred A vector of predicted labels, same length as \code{gold}.
#' @param metrics Character vector of metrics to compute. Default
#'   \code{c("precision", "recall", "f1_macro", "accuracy",
#'   "balanced_accuracy", "mcc")}.
#' @param positive Optional character: which level to treat as the
#'   positive class for binary-style precision/recall. If \code{NULL}
#'   (default), all reported metrics are macro-averaged.
#'
#' @return A one-row data frame with one column per metric requested.
#'
#' @examples
#' \dontrun{
#'   valid(gold = labels$human, pred = labels$gpt5)
#' }
#'
#' @export
valid <- function(gold, pred,
                  metrics = c("precision", "recall", "f1_macro",
                              "f1_weighted", "accuracy",
                              "balanced_accuracy", "mcc"),
                  positive = NULL) {
  if (length(gold) != length(pred)) {
    stop("`gold` and `pred` must have the same length.", call. = FALSE)
  }
  gold <- as.character(gold)
  pred <- as.character(pred)

  classes <- sort(unique(c(gold, pred)))
  cm <- table(factor(gold, levels = classes),
              factor(pred, levels = classes))

  per_class <- .per_class_prf(cm)

  out <- list()

  if ("precision" %in% metrics) {
    out$precision <- if (is.null(positive)) mean(per_class$precision, na.rm = TRUE)
                     else per_class$precision[positive]
  }
  if ("recall" %in% metrics) {
    out$recall    <- if (is.null(positive)) mean(per_class$recall, na.rm = TRUE)
                     else per_class$recall[positive]
  }
  if ("f1_macro" %in% metrics) {
    out$f1_macro  <- mean(per_class$f1, na.rm = TRUE)
  }
  if ("f1_weighted" %in% metrics) {
    support <- rowSums(cm)
    w <- support / sum(support)
    out$f1_weighted <- sum(per_class$f1 * w, na.rm = TRUE)
  }
  if ("accuracy" %in% metrics) {
    out$accuracy  <- sum(diag(cm)) / sum(cm)
  }
  if ("balanced_accuracy" %in% metrics) {
    out$balanced_accuracy <- mean(per_class$recall, na.rm = TRUE)
  }
  if ("mcc" %in% metrics) {
    out$mcc <- .mcc_multiclass(cm)
  }

  as.data.frame(out, stringsAsFactors = FALSE)
}


.per_class_prf <- function(cm) {
  tp <- diag(cm)
  fp <- colSums(cm) - tp
  fn <- rowSums(cm) - tp

  precision <- tp / (tp + fp)
  recall    <- tp / (tp + fn)
  f1        <- 2 * precision * recall / (precision + recall)

  precision[is.nan(precision)] <- NA
  recall[is.nan(recall)]       <- NA
  f1[is.nan(f1)]               <- NA

  names(precision) <- names(recall) <- names(f1) <- rownames(cm)
  list(precision = precision, recall = recall, f1 = f1)
}


# Multi-class MCC (Gorodkin 2004 generalization).
.mcc_multiclass <- function(cm) {
  N <- sum(cm)
  if (N == 0) return(NA_real_)
  t_k <- rowSums(cm)
  p_k <- colSums(cm)
  c_   <- sum(diag(cm))
  s_sq <- N * N

  num <- c_ * N - sum(t_k * p_k)
  den <- sqrt(s_sq - sum(p_k^2)) * sqrt(s_sq - sum(t_k^2))
  if (den == 0) return(NA_real_)
  num / den
}


#' Dual-track metrics: reliability + validity, side by side
#'
#' Computes \code{\link{reliab}} on \code{ratings} and
#' \code{\link{valid}} on \code{(gold, pred)} and returns a list with
#' the two tidy data frames. Use when you want to report agreement and
#' accuracy together (the C-R-A-F-T \emph{R} step).
#'
#' @param ratings Data frame of rater columns for reliability.
#' @param gold Gold-standard label vector.
#' @param pred Either a single predicted-label vector, or a
#'   \emph{named} list of predicted-label vectors (one entry per
#'   annotator: \code{list("GPT-5" = ..., "Gemini-3" = ..., "Llama-3.3" = ...)}).
#'   When a list is supplied, the returned \code{validity} table has
#'   one row per annotator with an additional \code{annotator}
#'   column.
#' @param pred_name Optional display name when \code{pred} is a single
#'   vector. Ignored when \code{pred} is a named list (the list names
#'   are used). Downstream renderers (\code{\link{report}}) use this
#'   to label the validity table.
#' @param reliability_method,reliability_level,reliability_weights
#'   Passed through to \code{\link{reliab}}.
#' @param validity_metrics Passed through to \code{\link{valid}}.
#'
#' @return A list with elements \code{reliability}, \code{validity},
#'   and \code{pred_name}. When \code{pred} is a named list,
#'   \code{validity} is a stacked data frame with an \code{annotator}
#'   column and \code{pred_name} is the character vector of annotator
#'   names.
#'
#' @export
dual <- function(ratings,
                 gold,
                 pred,
                 pred_name = NULL,
                 reliability_method = "auto",
                 reliability_level  = "nominal",
                 reliability_weights = "equal",
                 validity_metrics = c("precision", "recall",
                                      "f1_macro", "f1_weighted",
                                      "accuracy", "balanced_accuracy",
                                      "mcc")) {

  is_multi <- is.list(pred) && !is.data.frame(pred)

  if (is_multi) {
    if (is.null(names(pred)) || any(names(pred) == "")) {
      stop("When `pred` is a list it must be a named list, e.g. ",
           "list(\"GPT-5\" = vec1, \"Gemini-3\" = vec2).",
           call. = FALSE)
    }
    valid_rows <- lapply(names(pred), function(nm) {
      v <- valid(gold = gold, pred = pred[[nm]], metrics = validity_metrics)
      cbind(annotator = nm, v, stringsAsFactors = FALSE)
    })
    valid_df  <- do.call(rbind, valid_rows)
    pred_name <- names(pred)
  } else {
    if (is.null(pred_name)) {
      pred_name <- tryCatch(deparse(substitute(pred)),
                            error = function(e) "predictor")
      pred_name <- sub(".*\\$", "", pred_name)
      pred_name <- sub(".*\\[\\[.+\\]\\]", "predictor", pred_name)
    }
    valid_df <- valid(gold = gold, pred = pred, metrics = validity_metrics)
  }

  list(
    reliability = reliab(ratings,
                         method = reliability_method,
                         level  = reliability_level,
                         weights = reliability_weights),
    validity    = valid_df,
    pred_name   = pred_name
  )
}
