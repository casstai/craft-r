# Generate a CRAFT reproducibility report

Renders an Rmd template that records the full CRAFT run: which LLM,
which version, which prompt(s), all metrics, thresholds, audit
decisions, and any DSL correction applied. Scholars include this report
alongside their paper as a methods supplement so the LLM workflow is
reproducible.

## Usage

``` r
report(
  role_task,
  llm,
  version,
  prompt_path,
  metrics = NULL,
  audit = NULL,
  dsl = NULL,
  thresholds = NULL,
  output = "craft_report.html",
  format = NULL,
  template = NULL
)
```

## Arguments

- role_task:

  A `craft_role` object from
  [`role`](https://casstai.github.io/craft-r/reference/role.md).

- llm:

  Character: model name (e.g. `"GPT-5"`).

- version:

  Character: exact model identifier (e.g. `"gpt-5-2025-09-15"`).

- prompt_path:

  Path to a text file containing the prompt(s) used in the study. The
  file contents are pasted verbatim into the report.

- metrics:

  A list with elements `reliability` and `validity` (from
  [`dual`](https://casstai.github.io/craft-r/reference/dual.md)) or a
  [`stab`](https://casstai.github.io/craft-r/reference/stab.md) result.

- audit:

  Optional data frame from
  [`audit`](https://casstai.github.io/craft-r/reference/audit.md). If
  supplied, the report shows 1-2 example rows with text and rationales
  to illustrate the audit step.

- dsl:

  Optional data frame from
  [`dsl_cmp`](https://casstai.github.io/craft-r/reference/dsl_cmp.md).

- thresholds:

  Named list of threshold decisions (e.g.
  `list(confidence = 0.55, low = 0.31)`).

- output:

  Path to write the rendered report. If relative, resolved against
  [`getwd()`](https://rdrr.io/r/base/getwd.html). Default
  `"craft_report.html"` writes to the current working directory. Use
  `"craft_report.pdf"` for PDF.

- format:

  Optional explicit format: `"html"`, `"pdf"`, or `"both"`. If `NULL`
  (default), inferred from the `output` extension. When `"both"`, writes
  both an HTML and a PDF file alongside each other.

- template:

  Optional alternative Rmd template. Default uses the one shipped in
  `inst/rmd/report_template.Rmd`.

## Value

Invisibly returns the absolute path(s) to the rendered report(s).

## Details

The report is written as \*\*prose\*\* (not raw R output) so it can be
submitted as a methods-transparency supplement. Format is detected from
the `output` file extension: `.html` for HTML output, `.pdf` for PDF
(requires a LaTeX install, e.g. via
[`tinytex::install_tinytex()`](https://rdrr.io/pkg/tinytex/man/install_tinytex.html)).
The default writes to the user's current working directory so the file
is easy to find.

## Examples

``` r
if (FALSE) { # \dontrun{
  report(
    role_task   = rt,
    llm         = "GPT-5",
    version     = "gpt-5-2025-09-15",
    prompt_path = "prompts/dev4.txt",
    metrics     = dt,
    audit       = a,
    dsl         = dsl_results,
    thresholds  = list(confidence = 0.55, low = 0.31),
    output      = "my_craft_report.pdf"   # writes to getwd()
  )

  # Both html and pdf in one call:
  report(..., output = "my_craft_report", format = "both")
} # }
```
