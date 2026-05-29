#' Design-based supervised learning correction (T step of CRAFT)
#'
#' Wraps \code{dsl::dsl()} so misclassification uncertainty in the
#' LLM-generated labels propagates into the downstream regression
#' estimates.
#'
#' @param data A data frame containing the predicted label column, the
#'   gold-label column (for the audited subset), the sample-inclusion
#'   probability column, and any covariates / fixed-effect indices /
#'   cluster identifiers used in \code{formula}.
#' @param formula A formula expression for the outcome model
#'   (e.g. \code{sup ~ ideology + female + senate + education}).
#' @param predicted_var Character name of the outcome column in
#'   \code{data}.
#' @param prediction Character name of the LLM-prediction column.
#' @param sample_prob Character name of the inclusion-probability
#'   column.
#' @param model Underlying regression model passed to \code{dsl::dsl()}.
#'   Default \code{"felm"} for fixed-effect linear models.
#' @param fixed_effect,index,cluster Passed through to \code{dsl::dsl()}.
#' @param ... Additional arguments forwarded to \code{dsl::dsl()}.
#'
#' @return The object returned by \code{dsl::dsl()}.
#'
#' @examples
#' \dontrun{
#'   dsl_out <- dsl_fit(
#'     data    = legis_df,
#'     formula = sup ~ shor_ideo + per_mining + female + senate + perc_bchhigherE,
#'     predicted_var = "sup",
#'     prediction    = "pred_sup",
#'     sample_prob   = "cand_incl_prob_all",
#'     fixed_effect  = "oneway",
#'     index   = "state",
#'     cluster = "state"
#'   )
#' }
#'
#' @export
dsl_fit <- function(data, formula,
                        predicted_var, prediction, sample_prob,
                        model = "felm",
                        fixed_effect = NULL,
                        index = NULL,
                        cluster = NULL,
                        ...) {
  if (!requireNamespace("dsl", quietly = TRUE)) {
    stop("Package 'dsl' is required. Install with: ",
         "remotes::install_github('naoki-egami/dsl')", call. = FALSE)
  }
  dsl::dsl(
    model         = model,
    formula       = formula,
    predicted_var = predicted_var,
    prediction    = prediction,
    sample_prob   = sample_prob,
    fixed_effect  = fixed_effect,
    index         = index,
    cluster       = cluster,
    data          = data,
    ...
  )
}


#' Compare naive vs. design-based corrected estimates
#'
#' Runs the same regression with and without DSL correction and returns
#' a tidy comparison data frame.
#'
#' @param data Data frame.
#' @param formula Outcome formula. The LHS \code{predicted_var} is
#'   replaced by \code{prediction} for the naive fit.
#' @param predicted_var,prediction,sample_prob,fixed_effect,index,cluster
#'   See \code{\link{dsl_fit}}.
#' @param ... Forwarded to \code{dsl::dsl()}.
#'
#' @return A long data frame with columns \code{term}, \code{model}
#'   (one of \code{"Original"} or \code{"DSL"}), \code{estimate},
#'   \code{std.error}, \code{conf.low}, \code{conf.high},
#'   \code{p.value}.
#'
#' @export
dsl_cmp <- function(data, formula,
                        predicted_var, prediction, sample_prob,
                        fixed_effect = NULL,
                        index = NULL,
                        cluster = NULL,
                        ...) {
  if (!requireNamespace("dsl", quietly = TRUE)) {
    stop("Package 'dsl' is required. Install with: ",
         "remotes::install_github('naoki-egami/dsl')", call. = FALSE)
  }
  if (!requireNamespace("lfe", quietly = TRUE)) {
    stop("Package 'lfe' is required for the naive fixed-effect comparison.",
         call. = FALSE)
  }

  # ----- Naive (predicted label as outcome) -----
  lhs <- if (!is.null(fixed_effect) && fixed_effect == "oneway" && !is.null(index)) {
    paste0(prediction, " ~ ",
           paste(all.vars(formula[[3]]), collapse = " + "),
           " | ", index, " | 0 | ", if (!is.null(cluster)) cluster else "0")
  } else {
    paste0(prediction, " ~ ", paste(all.vars(formula[[3]]), collapse = " + "))
  }
  naive_fit <- lfe::felm(as.formula(lhs), data = data)
  naive_tidy <- .tidy_felm(naive_fit, label = "Original")

  # ----- DSL-corrected -----
  dsl_obj <- dsl_fit(
    data          = data,
    formula       = formula,
    predicted_var = predicted_var,
    prediction    = prediction,
    sample_prob   = sample_prob,
    model         = "felm",
    fixed_effect  = fixed_effect,
    index         = index,
    cluster       = cluster,
    ...
  )
  dsl_tidy <- .tidy_dsl(dsl_obj, label = "DSL")

  rbind(naive_tidy, dsl_tidy)
}


.tidy_felm <- function(fit, label) {
  s <- summary(fit)$coefficients
  data.frame(
    term      = rownames(s),
    model     = label,
    estimate  = s[, 1],
    std.error = s[, 2],
    conf.low  = s[, 1] - 1.96 * s[, 2],
    conf.high = s[, 1] + 1.96 * s[, 2],
    p.value   = s[, ncol(s)],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}


.tidy_dsl <- function(fit, label) {
  s <- summary(fit)
  s_df <- as.data.frame(s)
  data.frame(
    term      = rownames(s_df),
    model     = label,
    estimate  = s_df[["Estimate"]],
    std.error = s_df[["Std. Error"]],
    conf.low  = s_df[["CI Lower"]],
    conf.high = s_df[["CI Upper"]],
    p.value   = s_df[["p value"]],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
