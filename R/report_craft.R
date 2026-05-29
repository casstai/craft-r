#' Generate a CRAFT reproducibility report
#'
#' Renders an Rmd template that records the full CRAFT run: which LLM,
#' which version, which prompt(s), all metrics, thresholds, audit
#' decisions, and any DSL correction applied. Scholars include this
#' report alongside their paper as a methods supplement so the LLM
#' workflow is reproducible.
#'
#' The report is written as **prose** (not raw R output) so it can be
#' submitted as a methods-transparency supplement. Format is detected
#' from the \code{output} file extension: \code{.html} for HTML output,
#' \code{.pdf} for PDF (requires a LaTeX install, e.g. via
#' \code{tinytex::install_tinytex()}). The default writes to the
#' user's current working directory so the file is easy to find.
#'
#' @param role_task A \code{craft_role} object from \code{\link{role}}.
#' @param llm Character: model name (e.g. \code{"GPT-5"}).
#' @param version Character: exact model identifier (e.g.
#'   \code{"gpt-5-2025-09-15"}).
#' @param prompt_path Path to a text file containing the prompt(s)
#'   used in the study. The file contents are pasted verbatim into
#'   the report.
#' @param metrics A list with elements \code{reliability} and
#'   \code{validity} (from \code{\link{dual}}) or a \code{\link{stab}}
#'   result.
#' @param audit Optional data frame from \code{\link{audit}}. If
#'   supplied, the report shows 1-2 example rows with text and
#'   rationales to illustrate the audit step.
#' @param dsl Optional data frame from \code{\link{dsl_cmp}}.
#' @param thresholds Named list of threshold decisions (e.g.
#'   \code{list(confidence = 0.55, low = 0.31)}).
#' @param output Path to write the rendered report. If relative,
#'   resolved against \code{getwd()}. Default
#'   \code{"craft_report.html"} writes to the current working
#'   directory. Use \code{"craft_report.pdf"} for PDF.
#' @param format Optional explicit format: \code{"html"}, \code{"pdf"},
#'   or \code{"both"}. If \code{NULL} (default), inferred from the
#'   \code{output} extension. When \code{"both"}, writes both an HTML
#'   and a PDF file alongside each other.
#' @param template Optional alternative Rmd template. Default uses the
#'   one shipped in \code{inst/rmd/report_template.Rmd}.
#'
#' @return Invisibly returns the absolute path(s) to the rendered
#'   report(s).
#'
#' @examples
#' \dontrun{
#'   report(
#'     role_task   = rt,
#'     llm         = "GPT-5",
#'     version     = "gpt-5-2025-09-15",
#'     prompt_path = "prompts/dev4.txt",
#'     metrics     = dt,
#'     audit       = a,
#'     dsl         = dsl_results,
#'     thresholds  = list(confidence = 0.55, low = 0.31),
#'     output      = "my_craft_report.pdf"   # writes to getwd()
#'   )
#'
#'   # Both html and pdf in one call:
#'   report(..., output = "my_craft_report", format = "both")
#' }
#'
#' @export
report <- function(role_task,
                   llm,
                   version,
                   prompt_path,
                   metrics = NULL,
                   audit = NULL,
                   dsl = NULL,
                   thresholds = NULL,
                   output = "craft_report.html",
                   format = NULL,
                   template = NULL) {

  if (!inherits(role_task, "craft_role")) {
    stop("`role_task` must come from `role()`.", call. = FALSE)
  }
  if (!file.exists(prompt_path)) {
    stop("Prompt file not found: ", prompt_path, call. = FALSE)
  }
  if (is.null(template)) {
    template <- system.file("rmd", "report_template.Rmd", package = "craft")
    # Dev mode fallback (devtools::load_all() before devtools::install())
    if (template == "" || !file.exists(template)) {
      candidates <- c(
        file.path("inst", "rmd", "report_template.Rmd"),
        file.path("..", "inst", "rmd", "report_template.Rmd")
      )
      hit <- candidates[file.exists(candidates)]
      if (length(hit) > 0) {
        template <- normalizePath(hit[1])
      } else {
        stop("Report template not found. Install the package or run ",
             "from the package root.", call. = FALSE)
      }
    }
  }

  # Resolve output to user's working directory if relative
  if (!.is_absolute_path(output)) {
    output <- file.path(getwd(), output)
  }
  output <- normalizePath(output, mustWork = FALSE)

  # Detect format from extension if not given
  if (is.null(format)) {
    ext <- tolower(tools::file_ext(output))
    format <- if (ext == "pdf") "pdf"
              else if (ext == "html" || ext == "") "html"
              else stop("Unsupported output extension: .", ext,
                        ". Use .html or .pdf, or set format = ",
                        "\"html\"/\"pdf\"/\"both\".", call. = FALSE)
  }
  format <- match.arg(format, c("html", "pdf", "both"))

  prompt_text <- paste(readLines(prompt_path, warn = FALSE), collapse = "\n")

  params <- list(
    role_task  = role_task,
    llm        = llm,
    version    = version,
    prompt     = prompt_text,
    metrics    = metrics,
    audit      = audit,
    dsl        = dsl,
    thresholds = thresholds,
    timestamp  = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )

  written <- character()

  if (format %in% c("html", "both")) {
    out_html <- if (format == "both") .swap_ext(output, "html") else output
    rmarkdown::render(
      input         = template,
      output_file   = out_html,
      output_format = rmarkdown::html_document(toc = TRUE, toc_depth = 2),
      params        = params,
      envir         = new.env(parent = globalenv()),
      quiet         = TRUE
    )
    message("Wrote ", out_html)
    written <- c(written, out_html)
  }

  if (format %in% c("pdf", "both")) {
    if (!.have_latex()) {
      stop("PDF output requires LaTeX. Install via tinytex::install_tinytex()",
           " or pick format = \"html\".", call. = FALSE)
    }
    out_pdf <- if (format == "both") .swap_ext(output, "pdf") else output
    rmarkdown::render(
      input         = template,
      output_file   = out_pdf,
      # Use xelatex so Unicode characters in prompts (≤, →, em-dashes,
      # CJK, etc.) render without LaTeX errors.
      output_format = rmarkdown::pdf_document(
        toc = TRUE, toc_depth = 2, latex_engine = "xelatex"
      ),
      params        = params,
      envir         = new.env(parent = globalenv()),
      quiet         = TRUE
    )
    message("Wrote ", out_pdf)
    written <- c(written, out_pdf)
  }

  invisible(written)
}


# ---- internal helpers ----

.is_absolute_path <- function(p) {
  grepl("^(/|~|[A-Za-z]:[/\\\\])", p)
}

.swap_ext <- function(path, new_ext) {
  base <- tools::file_path_sans_ext(path)
  paste0(base, ".", new_ext)
}

.have_latex <- function() {
  if (requireNamespace("tinytex", quietly = TRUE) &&
      tinytex::is_tinytex()) return(TRUE)
  nzchar(Sys.which("pdflatex")) || nzchar(Sys.which("xelatex")) ||
    nzchar(Sys.which("latex"))
}
