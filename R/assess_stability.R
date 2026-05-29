#' Stability across prompts or models (A step of CRAFT)
#'
#' Given a named list of predicted-label vectors (one per prompt or
#' model variant) plus a gold reference, compute reliability + validity
#' for each variant and stack the results into a tidy comparison table.
#'
#' @param predictions A named list of prediction vectors, all of the
#'   same length. Names appear as the \code{variant} column of the
#'   returned table.
#' @param gold Gold-standard reference vector, same length as each
#'   prediction.
#' @param reliability_method,reliability_level Passed to
#'   \code{\link{reliab}}.
#' @param validity_metrics Passed to \code{\link{valid}}.
#'
#' @return A data frame with one row per variant.
#'
#' @examples
#' \dontrun{
#'   stab(
#'     list("GPT-5" = labels$gpt5,
#'          "Gemini-3" = labels$gemini,
#'          "Llama-3.3" = labels$llama),
#'     gold = labels$human
#'   )
#' }
#'
#' @export
stab <- function(predictions, gold,
                 reliability_method = "cohen",
                 reliability_level  = "nominal",
                 validity_metrics = c("f1_macro", "mcc",
                                      "balanced_accuracy")) {
  if (is.null(names(predictions)) || any(names(predictions) == "")) {
    stop("`predictions` must be a named list (variant -> prediction vector).",
         call. = FALSE)
  }

  rows <- lapply(names(predictions), function(nm) {
    pred <- predictions[[nm]]
    rel  <- reliab(
      data.frame(gold = gold, pred = pred),
      method = reliability_method,
      level  = reliability_level
    )
    val <- valid(gold = gold, pred = pred, metrics = validity_metrics)
    cbind(
      data.frame(variant = nm, stringsAsFactors = FALSE),
      data.frame(reliability_method = rel$method,
                 reliability_value  = rel$value,
                 stringsAsFactors = FALSE),
      val
    )
  })
  do.call(rbind, rows)
}
