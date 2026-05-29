# Getting Started with craft (5-minute tutorial)

> **Demo data, not real data.** The `craft_demo.csv` file used below is
> **synthetic but structurally based on the climate-stance demonstration
> used in the CRAFT paper** (Ko, Tai & Webb Williams). Climate stance is
> used to illustrate the framework — CRAFT itself is domain-general.
> Five of the rows carry text and rationales lifted verbatim from the
> paper’s Table `tab:example`; the rest are synthetic label sequences
> with realistic error rates. No row corresponds to any unpublished real
> annotation.

This tutorial gets you from zero to a complete CRAFT evaluation in about
five minutes. For the deeper end-to-end example (including DSL
correction), see
[`vignette("craft-walkthrough")`](https://casstai.github.io/craft-r/articles/craft-walkthrough.md).

## What you need

A data frame with one column per rater (annotator or LLM), a
gold-standard column, and optionally per-rater confidence scores.

``` r

demo <- read.csv(
  system.file("extdata", "craft_demo.csv", package = "craft")
)
head(demo)
#>            id
#> 1 paper_ex_01
#> 2 paper_ex_02
#> 3 paper_ex_03
#> 4 paper_ex_04
#> 5 paper_ex_05
#> 6     syn_001
#>                                                                                                                                                                                                                                                 text
#> 1                                                                                                                       the irony of holding up environment budget negotiations over a rule to address air quality and climate change is nonsensical
#> 2 whats going on in texas is unconscionable people are dying bc of the power outage winter storm due to home fires carbon monoxide poisoning big impact on bipoc communities this was preventable blaming wind turbines amp renewables is ridiculous
#> 3                                                                                                                                                 tell the army corps the kxl pipeline endangers the health of families and kids deny the 404 permit
#> 4                                joe biden cant even earn our votes because his opinions are bought and paid for by the people supporting the policies we oppose fracking fossilfuels bigpharma biginsurance militaryindustrialcomplex to name a few
#> 5                                                                                                          RT @RBReich: Joe Manchin, who has repeatedly blocked efforts to combat climate change, collects 500,000 a year from coal stocks dividends
#> 6                                                                                                                                                                                                                                                   
#>   gold_standard gpt5_label gemini3_label llama3_label confidence_gpt5
#> 1       support    support       support      support       0.8800000
#> 2       support    support       support      support       0.9100000
#> 3       support    support       support      support       0.8300000
#> 4       support    support       support      support       0.8600000
#> 5       support    support       support     opposing       0.8400000
#> 6      opposing    support      opposing      support       0.6170062
#>   confidence_gemini3 confidence_llama3
#> 1          0.8500000         0.7100000
#> 2          0.8900000         0.7500000
#> 3          0.8100000         0.6900000
#> 4          0.8400000         0.7200000
#> 5          0.8200000         0.6200000
#> 6          0.8150175         0.4217787
#>                                                                                              rationale_gpt5
#> 1                                      criticism of budget obstruction indicates support for climate policy
#> 2        defending renewables against blame for power outages indicates support for clean energy technology
#> 3                         fossil pipeline opposition is a proxy cue; denying permit supports climate action
#> 4 explicitly listing fracking and fossil fuels as policies to oppose signals support for climate mitigation
#> 5                        criticizing Manchin for blocking climate action signals support for climate policy
#> 6                                                                                                          
#>                                                                   rationale_gemini3
#> 1              framing budget obstruction as nonsensical signals pro-climate stance
#> 2                         rejecting renewable-blame narrative endorses clean energy
#> 3 opposing fossil-fuel pipeline construction signals support for climate mitigation
#> 4       naming fossil fuels as opposed policies indicates climate-supportive stance
#> 5      criticizing obstruction of climate efforts implies support for those efforts
#> 6                                                                                  
#>                                                 rationale_llama3
#> 1     post mentions climate change and policy with critical tone
#> 2                      post mentions renewables and storm impact
#> 3                       post calls for permit denial on pipeline
#> 4                 post lists fossil fuels among opposed policies
#> 5 proxy cues 'coal stocks' and 'blocks efforts' imply opposition
#> 6                                                               
#>                       source
#> 1 main.tex Table tab:example
#> 2 main.tex Table tab:example
#> 3 main.tex Table tab:example
#> 4 main.tex Table tab:example
#> 5 main.tex Table tab:example
#> 6                  synthetic
```

Columns: `id`, `gold_standard`, `gpt5_label`, `gemini3_label`,
`llama3_label`, plus a `confidence_*` column per LLM. Labels are binary
(`support` / `opposing`); uncertainty is captured through per-LLM
confidence scores (R, A, F steps) and via the implicit `1 - sup - opp`
residual at the legislator level (T step), not as a third label class.

## Step 1 (C): Document the role

``` r

rt <- role(conception  = "annotator",
           task        = "classify climate stance",
           gold        = TRUE,
           prompt_type = "zero-shot")
rt
#> <craft role>
#>   Conception : annotator
#>   Task       : classify climate stance
#>   Gold labels: TRUE
#>   Prompt type: zero-shot
#>   Suggested reliability methods: cohen, weighted, fleiss, kripp
#>   Suggested validity metrics  : precision, recall, f1_macro, f1_weighted, mcc, balanced_accuracy
#>   Reliability is central; validity against the gold subset is also reported.
```

## Step 2 (R): Compute reliability + validity

Pick the reliability metric that fits your data. For four categorical
raters (one human + three LLMs), Krippendorff’s alpha is appropriate:

``` r

reliab(demo[, c("gold_standard", "gpt5_label",
                "gemini3_label", "llama3_label")],
       method = "kripp", level = "nominal")
#>                       method     value n_raters n_items
#> 1 krippendorff_alpha_nominal 0.5708223        4      50
```

Pairwise Cohen’s kappa - every rater pair separately:

``` r

reliab_pairs(demo[, c("gold_standard", "gpt5_label",
                      "gemini3_label", "llama3_label")],
             method = "cohen")
#>          RaterA        RaterB method     value
#> 1 gold_standard    gpt5_label  cohen 0.8960499
#> 2 gold_standard gemini3_label  cohen 0.8960499
#> 3 gold_standard  llama3_label  cohen 0.3383743
#> 4    gpt5_label gemini3_label  cohen 0.7920998
#> 5    gpt5_label  llama3_label  cohen 0.3383743
#> 6 gemini3_label  llama3_label  cohen 0.2438563
```

Validity vs. gold (you pick the metrics you care about):

``` r

valid(gold = demo$gold_standard,
      pred = demo$gpt5_label,
      metrics = c("f1_macro", "f1_weighted", "mcc", "accuracy"))
#>    f1_macro f1_weighted accuracy       mcc
#> 1 0.9480249        0.96     0.96 0.8960499
```

Both in one call:

``` r

# Single annotator vs. gold
dual(
  ratings   = demo[, c("gold_standard", "gpt5_label")],
  gold      = demo$gold_standard,
  pred      = demo$gpt5_label,
  pred_name = "GPT-5",
  reliability_method = "cohen",
  validity_metrics   = c("f1_macro", "f1_weighted", "mcc")
)
#> $reliability
#>   method     value n_raters n_items      p_value
#> 1  cohen 0.8960499        2      50 2.357616e-10
#> 
#> $validity
#>    f1_macro f1_weighted       mcc
#> 1 0.9480249        0.96 0.8960499
#> 
#> $pred_name
#> [1] "GPT-5"
```

To get validity for **all three annotators in one call**, pass a named
list of prediction vectors:

``` r

dual(
  ratings = demo[, c("gold_standard", "gpt5_label",
                     "gemini3_label", "llama3_label")],
  gold = demo$gold_standard,
  pred = list(
    "GPT-5"     = demo$gpt5_label,
    "Gemini-3"  = demo$gemini3_label,
    "Llama-3.3" = demo$llama3_label
  ),
  reliability_method = "kripp",
  validity_metrics   = c("f1_macro", "f1_weighted", "mcc")
)
#> $reliability
#>                       method     value n_raters n_items
#> 1 krippendorff_alpha_nominal 0.5708223        4      50
#> 
#> $validity
#>   annotator  f1_macro f1_weighted       mcc
#> 1     GPT-5 0.9480249   0.9600000 0.8960499
#> 2  Gemini-3 0.9480249   0.9600000 0.8960499
#> 3 Llama-3.3 0.6666667   0.7306667 0.3445871
#> 
#> $pred_name
#> [1] "GPT-5"     "Gemini-3"  "Llama-3.3"
```

## Step 3 (A): Compare across models

``` r

stab(
  predictions = list(
    "GPT-5"     = demo$gpt5_label,
    "Gemini-3"  = demo$gemini3_label,
    "Llama-3.3" = demo$llama3_label
  ),
  gold = demo$gold_standard
)
#>     variant reliability_method reliability_value  f1_macro balanced_accuracy
#> 1     GPT-5              cohen         0.8960499 0.9480249         0.9480249
#> 2  Gemini-3              cohen         0.8960499 0.9480249         0.9480249
#> 3 Llama-3.3              cohen         0.3383743 0.6666667         0.6860707
#>         mcc
#> 1 0.8960499
#> 2 0.8960499
#> 3 0.3445871
```

## Step 4 (F): Audit

``` r

ann <- data.frame(
  id           = demo$id,
  label_a      = demo$gpt5_label,
  label_b      = demo$gemini3_label,
  confidence_a = demo$confidence_gpt5,
  confidence_b = demo$confidence_gemini3
)
a <- audit(ann, confidence_threshold = 0.55, low_threshold = 0.31)
table(a$audit_status)
#> 
#>    agreement disagreement 
#>           46            4
```

## Step 5 (T): DSL correction

[`dsl_fit()`](https://casstai.github.io/craft-r/reference/dsl_fit.md)
and
[`dsl_cmp()`](https://casstai.github.io/craft-r/reference/dsl_cmp.md)
propagate misclassification uncertainty into a downstream regression.
See
[`vignette("craft-walkthrough")`](https://casstai.github.io/craft-r/articles/craft-walkthrough.md)
for the full T-step example.

## Emit a reproducibility report

The report is written in prose and can render to HTML or PDF. The output
file lands in your current working directory by default, or at any path
you specify. The PDF output requires LaTeX (one-time
[`tinytex::install_tinytex()`](https://rdrr.io/pkg/tinytex/man/install_tinytex.html)).

``` r

report(
  role_task   = rt,
  llm         = "GPT-5",
  version     = "gpt-5-2025-09-15",
  prompt_path = system.file("extdata", "prompt_dev4.txt", package = "craft"),
  metrics     = dual(
    ratings = demo[, c("gold_standard", "gpt5_label")],
    gold    = demo$gold_standard,
    pred    = demo$gpt5_label,
    reliability_method = "cohen"
  ),
  thresholds  = list(confidence = 0.55, low = 0.31),
  output      = "craft_report.html"      # writes to getwd()
)

# Or generate both an HTML preview AND a PDF for a paper supplement:
report(..., output = "craft_report", format = "both")
```

## Where to go next

- [`vignette("craft-walkthrough")`](https://casstai.github.io/craft-r/articles/craft-walkthrough.md)
  — the deeper example with DSL.
- [`?reliab`](https://casstai.github.io/craft-r/reference/reliab.md) —
  full list of reliability methods and when to use each.
- [`?report`](https://casstai.github.io/craft-r/reference/report.md) —
  argument reference for the reproducibility report.
