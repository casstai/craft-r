# Producing a Transparency Report for Journal Submission

## Why this matters

Replication and transparency norms for studies that use large language
models are still emerging. Different journals will adopt different
disclosure requirements over time, and the most defensible choice
authors can make is to document the LLM pipeline thoroughly even when no
specific requirement is in place yet. Reviewers and future readers
benefit from knowing the exact model and version, the verbatim prompts,
the metrics that were computed against gold-standard human labels, the
threshold or decision rules applied, the audit decisions made, and any
correction applied for measurement error in downstream analyses.

[`craft::report()`](https://casstai.github.io/craft-r/reference/report.md)
bundles all of these into a single methods-supplement-style document
that can be circulated with coauthors, archived alongside replication
materials, or uploaded with a journal submission when called for. The
same call produces both an **HTML** version (with the prompt behind a
toggle, easy to share by email) and a **PDF** version (clean and
printable for archival use).

> **What this vignette covers.** A minimal end-to-end recipe: from
> existing LLM outputs and a gold-standard audit subset to a rendered
> transparency document. For more conceptual depth on each CRAFT step
> see
> [`vignette("craft-walkthrough")`](https://casstai.github.io/craft-r/articles/craft-walkthrough.md).

## Minimum inputs you need

To generate a publishable report you need:

1.  **A prompt text file** — the exact instruction issued to the model,
    saved as `.txt`. Don’t paraphrase it. Whatever you actually sent the
    API, that is what goes in this file.
2.  **LLM outputs** — model labels and (ideally) per-prediction
    confidence scores for every annotated case.
3.  **A gold-standard audited subset** — at least a few hundred
    human-coded cases against which to compute validity.
4.  **A DSL result** (if your downstream analysis is regression-based) —
    generated with
    [`dsl_cmp()`](https://casstai.github.io/craft-r/reference/dsl_cmp.md).

Everything else flows from these.

## A walked example using the package demo

The package ships synthetic demo data plus the actual codebook used in
the climate-stance demonstration of the CRAFT paper.

### Step 1 — describe the role of the LLM

``` r

rt <- role(
  conception  = "annotator",
  task        = "classify the climate stance of state legislators",
  gold        = TRUE,
  prompt_type = "zero-shot"
)
rt
#> <craft role>
#>   Conception : annotator
#>   Task       : classify the climate stance of state legislators
#>   Gold labels: TRUE
#>   Prompt type: zero-shot
#>   Suggested reliability methods: cohen, weighted, fleiss, kripp
#>   Suggested validity metrics  : precision, recall, f1_macro, f1_weighted, mcc, balanced_accuracy
#>   Reliability is central; validity against the gold subset is also reported.
```

The printed summary is exactly what will appear at the top of the
generated report.

### Step 2 — compute the metrics that go into the report

``` r

demo <- read.csv(
  system.file("extdata", "craft_demo.csv", package = "craft")
)

dt <- dual(
  ratings = demo[, c("gold_standard", "gpt5_label",
                     "gemini3_label", "llama3_label")],
  gold = demo$gold_standard,
  pred = list(
    "GPT-5"     = demo$gpt5_label,
    "Gemini-3"  = demo$gemini3_label,
    "Llama-3.3" = demo$llama3_label
  ),
  reliability_method = "kripp",
  validity_metrics = c("f1_macro", "f1_weighted", "mcc",
                       "balanced_accuracy")
)
```

The validity table will appear with one row per annotator. For a
single-annotator study just pass a vector instead of a list — see
[`?dual`](https://casstai.github.io/craft-r/reference/dual.md) for the
alternative form.

### Step 3 — record the audit decisions

``` r

ann <- data.frame(
  id                = demo$id,
  text              = demo$text,
  label_a           = demo$gpt5_label,
  label_b           = demo$gemini3_label,
  confidence_a      = demo$confidence_gpt5,
  confidence_b      = demo$confidence_gemini3,
  rationale_gpt5    = demo$rationale_gpt5,
  rationale_gemini3 = demo$rationale_gemini3,
  stringsAsFactors  = FALSE
)
a <- audit(ann, confidence_threshold = 0.55, low_threshold = 0.31)
```

The report quotes 1-2 illustrative cases from this object. Passing
`text` and `rationale_*` columns is what enables qualitative examples of
how human auditors used the model rationales to adjudicate borderline
labels — useful for any reader trying to understand how the annotation
pipeline made its decisions.

### Step 4 — run the DSL correction

``` r

load(system.file("extdata", "data.rda", package = "craft"))
dsl_results <- dsl_cmp(
  data    = data,
  formula = sup ~ shor_ideo + per_mining + female + senate + perc_bchhigherE,
  predicted_var = "sup",
  prediction    = "pred_sup",
  sample_prob   = "cand_incl_prob_all",
  fixed_effect  = "oneway",
  index   = "state",
  cluster = "state"
)
#> Cross-Fitting: 1/10..2/10..3/10..4/10..5/10..6/10..7/10..8/10..9/10..10/10..==================
#> DSL Specification:
#> ==================
#> Model:  felm (oneway)
#> Call:  sup ~ shor_ideo + per_mining + female + senate + perc_bchhigherE
#> Fixed Effects:  state
#> 
#> Predicted Variables:  sup
#> Prediction:  pred_sup
#> 
#> Number of Labeled Observations:  2800
#> Random Sampling for Labeling with Equal Probability:  No
#> (Sampling probabilities are defined in `sample_prob`)
#> 
#> =============
#> Coefficients:
#> =============
#>                 Estimate Std. Error CI Lower CI Upper p value    
#> shor_ideo        -0.1414     0.0018  -0.1450  -0.1378  0.0000 ***
#> per_mining       -0.0063     0.0007  -0.0077  -0.0049  0.0000 ***
#> female           -0.0007     0.0035  -0.0076   0.0062  0.4184    
#> senate           -0.0006     0.0040  -0.0086   0.0073  0.4382    
#> perc_bchhigherE   0.0041     0.0002   0.0037   0.0044  0.0000 ***
#> ---
#> Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 95% confidence intervals (CI) are reported.
#> Standard errors are clustered by state.
```

### Step 5 — emit the transparency document

``` r

report(
  role_task   = rt,
  llm         = "GPT-5",
  version     = "gpt-5-2025-09-15",
  prompt_path = system.file("extdata", "prompt_dev4.txt", package = "craft"),
  metrics     = dt,
  audit       = a,
  dsl         = dsl_results,
  thresholds  = list(confidence = 0.55, low = 0.31),
  output      = "craft_transparency_report",   # no extension
  format      = "both"                          # writes .html AND .pdf
)
```

The HTML file is for sharing with coauthors during preparation. The PDF
is suitable for archival use or for inclusion in supplementary materials
when relevant.

## What the rendered report contains

Each numbered section corresponds to one CRAFT step:

| Section | Content |
|----|----|
| **1. Construct role-task (C)** | How the LLM was conceptualized and what task it performed |
| **2. Model and prompt identification** | Model name, version string, and the verbatim prompt |
| **3. Threshold decisions** | Confidence cutoffs or other decision rules applied to outputs |
| **4. Report dual-track metrics (R)** | Reliability + validity tables (one row per annotator when multiple LLMs are compared) |
| **5. Assess stability (A)** | Cross-prompt or cross-model variability of the reported metrics |
| **6. Field audit (F)** | Distribution of audit statuses plus 1-2 illustrative cases with text and rationales |
| **7. Translate to inference (T)** | Original vs. DSL-corrected coefficient table |
| **8. Reproducibility note** | Timestamp + citation block |

If a section’s inputs are not supplied (for example, no DSL was run),
the section prints a brief note instead of an empty table.

## A pre-submission checklist for thoroughness

The model version string is the **exact API identifier**, not a
marketing name. (“GPT-5” → `gpt-5-2025-09-15`.)

The prompt file is **verbatim**, including system message, any few-shot
examples, and JSON-schema constraints.

The threshold values shown in Section 3 match the decision rules
described in your Methods section.

The audit examples in Section 6 represent the kinds of cases reviewers
will want to inspect (boundary cases, model disagreements, common-error
patterns).

The DSL columns in Section 7 use the same outcome and covariates as in
your main regression table.

## Citing `craft` in your methods section

A short example of language you can adapt:

> “We used GPT-5 (`gpt-5-2025-09-15`) and Gemini-3-Flash to
> independently annotate posts for climate stance. Inter-rater
> reliability between human and model annotators was assessed with
> Krippendorff’s alpha, and validity with macro-F1, weighted F1, and
> MCC. Disagreements between models were adjudicated by a human coder
> following the protocol described in our transparency supplement,
> generated using the `craft` R package (Tai & Ko, 2026).
> Misclassification uncertainty in the AI-generated labels was
> propagated into the regression estimates via design-based supervised
> learning (Egami et al., 2023; implemented in
> [`craft::dsl_cmp()`](https://casstai.github.io/craft-r/reference/dsl_cmp.md)).”

## Where to go next

- [`?report`](https://casstai.github.io/craft-r/reference/report.md) —
  full argument reference for the report function.
- [`vignette("craft-walkthrough")`](https://casstai.github.io/craft-r/articles/craft-walkthrough.md)
  — the deeper conceptual tour.
- [`vignette("getting-started")`](https://casstai.github.io/craft-r/articles/getting-started.md)
  — five-minute introduction.
