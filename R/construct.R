#' Construct role-task mapping (the C step of CRAFT)
#'
#' Records how the researcher is conceptualizing the LLM (annotator /
#' ML system / silicon participant) and the task it is performing
#' (classification, clustering, simulation). Returns an object that
#' downstream functions (especially \code{\link{report}}) consume.
#'
#' Also enforces the role-task / metric mapping from Ko, Tai & Webb
#' Williams (Table 1 of the CRAFT paper): given a conception + task +
#' presence-of-gold-labels, it suggests which families of reliability
#' and validity metrics apply.
#'
#' @param conception One of \code{"annotator"}, \code{"ml_system"},
#'   \code{"silicon"}. Aliases: \code{"like-human annotator"} maps to
#'   \code{"annotator"}; \code{"machine learning system"} maps to
#'   \code{"ml_system"}; \code{"silicon participant"} maps to
#'   \code{"silicon"}.
#' @param task A short string describing the task (e.g. \code{"classify
#'   climate stance"}).
#' @param gold Logical: are gold-standard human labels available?
#' @param prompt_type One of \code{"zero-shot"}, \code{"few-shot"},
#'   \code{"fine-tuned"}.
#'
#' @return An object of class \code{craft_role} with components
#'   \code{conception}, \code{task}, \code{gold}, \code{prompt_type},
#'   and \code{suggested_metrics}.
#'
#' @examples
#' role(conception = "annotator",
#'      task = "classify climate stance",
#'      gold = TRUE,
#'      prompt_type = "few-shot")
#'
#' @export
role <- function(conception,
                 task,
                 gold = TRUE,
                 prompt_type = c("zero-shot", "few-shot", "fine-tuned")) {
  conception <- .normalize_conception(conception)
  prompt_type <- match.arg(prompt_type)

  suggested <- .suggest_metrics(conception, gold, prompt_type)

  obj <- list(
    conception        = conception,
    task              = task,
    gold              = gold,
    prompt_type       = prompt_type,
    suggested_metrics = suggested
  )
  class(obj) <- c("craft_role", "list")
  obj
}


.normalize_conception <- function(x) {
  x <- tolower(trimws(x))
  if (x %in% c("annotator", "like-human annotator", "like-human", "human-like")) {
    return("annotator")
  }
  if (x %in% c("ml_system", "machine learning system", "ml", "classifier")) {
    return("ml_system")
  }
  if (x %in% c("silicon", "silicon participant", "synthetic", "synthetic agent")) {
    return("silicon")
  }
  stop("Unknown conception: ", x,
       ". Use one of 'annotator', 'ml_system', 'silicon'.", call. = FALSE)
}


.suggest_metrics <- function(conception, gold, prompt_type) {
  if (conception == "annotator") {
    rel <- c("cohen", "weighted", "fleiss", "kripp")
    val <- if (gold) c("precision", "recall", "f1_macro", "f1_weighted",
                       "mcc", "balanced_accuracy") else character(0)
    notes <- if (gold) {
      "Reliability is central; validity against the gold subset is also reported."
    } else {
      "Without gold labels, focus on inter-rater reliability with human coders to co-produce gold labels."
    }
  } else if (conception == "ml_system") {
    rel <- if (prompt_type == "zero-shot") c("kripp", "cohen") else character(0)
    val <- c("precision", "recall", "f1_macro", "f1_weighted",
             "mcc", "balanced_accuracy")
    notes <- if (prompt_type == "zero-shot") {
      "Zero-shot: report both reliability (kappa/alpha) and validity (F1/MCC) to detect systematic bias."
    } else {
      "Few-shot / fine-tuned: validity metrics suffice; reliability is supervisory rather than primary."
    }
  } else {  # silicon
    rel <- character(0)
    val <- c("mean_sd_alignment", "construct_validity", "external_validity")
    notes <- "Silicon participants: align mean / variance with human baseline; check construct + external validity."
  }
  list(reliability = rel, validity = val, notes = notes)
}


#' @export
print.craft_role <- function(x, ...) {
  cat("<craft role>\n")
  cat("  Conception : ", x$conception, "\n", sep = "")
  cat("  Task       : ", x$task, "\n", sep = "")
  cat("  Gold labels: ", x$gold, "\n", sep = "")
  cat("  Prompt type: ", x$prompt_type, "\n", sep = "")
  cat("  Suggested reliability methods: ",
      paste(x$suggested_metrics$reliability, collapse = ", "), "\n", sep = "")
  cat("  Suggested validity metrics  : ",
      paste(x$suggested_metrics$validity, collapse = ", "), "\n", sep = "")
  cat("  ", x$suggested_metrics$notes, "\n", sep = "")
  invisible(x)
}
