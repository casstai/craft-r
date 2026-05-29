# A C-R-A-F-T Walkthrough

> **Demo data, not real data.** The datasets used in this vignette are
> **synthetic but structurally based on the climate-stance demonstration
> used in the CRAFT paper** (Ko, Tai & Webb Williams). The CRAFT
> framework itself is general; climate stance is just one illustration.
> Class balance, error rates, and ideology distributions mimic the
> demonstration data, but no row corresponds to any actual legislator
> post. The five rationale-audit examples in the F step are lifted
> verbatim from the paper’s Table `tab:example`. The real demonstration
> dataset will replace this demo when the paper is published.

This vignette walks through the five C-R-A-F-T steps. Labels are binary
(`support` / `opposing`); uncertainty is captured through per-LLM
confidence scores (R, A, F steps) and via the implicit `1 - sup - opp`
residual at the legislator level (T step), not as a third label class.

## C — Construct role and task

``` r

rt <- role(
  conception  = "annotator",
  task        = "classify climate stance of state legislators on X",
  gold        = TRUE,
  prompt_type = "zero-shot"
)
rt
#> <craft role>
#>   Conception : annotator
#>   Task       : classify climate stance of state legislators on X
#>   Gold labels: TRUE
#>   Prompt type: zero-shot
#>   Suggested reliability methods: cohen, weighted, fleiss, kripp
#>   Suggested validity metrics  : precision, recall, f1_macro, f1_weighted, mcc, balanced_accuracy
#>   Reliability is central; validity against the gold subset is also reported.
```

The printed suggestions tell you which families of reliability and
validity metrics apply for this role-task combination.

## R — Report dual-track metrics

[`reliab()`](https://casstai.github.io/craft-r/reference/reliab.md)
dispatches one of six inter-rater reliability metrics (Cohen’s kappa,
weighted kappa, Fleiss’ kappa, Krippendorff’s alpha, ICC, or percent
agreement).
[`valid()`](https://casstai.github.io/craft-r/reference/valid.md)
computes validity (precision, recall, F1, MCC, etc.) against a gold
standard.
[`dual()`](https://casstai.github.io/craft-r/reference/dual.md) bundles
both into one call.

``` r

demo <- read.csv(
  system.file("extdata", "craft_demo.csv", package = "craft")
)
head(demo[, c("id", "gold_standard", "gpt5_label",
              "gemini3_label", "llama3_label")])
#>            id gold_standard gpt5_label gemini3_label llama3_label
#> 1 paper_ex_01       support    support       support      support
#> 2 paper_ex_02       support    support       support      support
#> 3 paper_ex_03       support    support       support      support
#> 4 paper_ex_04       support    support       support      support
#> 5 paper_ex_05       support    support       support     opposing
#> 6     syn_001      opposing    support      opposing      support

dt <- dual(
  ratings = demo[, c("gold_standard", "gpt5_label",
                     "gemini3_label", "llama3_label")],
  gold = demo$gold_standard,
  pred = list(                       # named list -> one row per
    "GPT-5"     = demo$gpt5_label,   # annotator in the validity table
    "Gemini-3"  = demo$gemini3_label,
    "Llama-3.3" = demo$llama3_label
  ),
  reliability_method = "kripp",      # >2 raters, nominal labels
  reliability_level  = "nominal",
  validity_metrics = c("f1_macro", "f1_weighted", "mcc",
                       "balanced_accuracy")
)
dt$reliability
#>                       method     value n_raters n_items
#> 1 krippendorff_alpha_nominal 0.5708223        4      50
dt$validity
#>   annotator  f1_macro f1_weighted balanced_accuracy       mcc
#> 1     GPT-5 0.9480249   0.9600000         0.9480249 0.8960499
#> 2  Gemini-3 0.9480249   0.9600000         0.9480249 0.8960499
#> 3 Llama-3.3 0.6666667   0.7306667         0.6860707 0.3445871
```

[`dual()`](https://casstai.github.io/craft-r/reference/dual.md) accepts
either a single `pred` vector or a named list of predictors. The list
form (above) gives one row per annotator in the validity table — useful
when comparing several LLMs against the same gold standard. The
single-vector form is shown below:

``` r

dual(ratings   = demo[, c("gold_standard", "gpt5_label")],
     gold      = demo$gold_standard,
     pred      = demo$gpt5_label,
     pred_name = "GPT-5",                # cleaner label in report()
     reliability_method = "cohen")
```

For pairwise Cohen’s kappa across every annotator pair (the data behind
a kappa heatmap):

``` r

reliab_pairs(
  demo[, c("gold_standard", "gpt5_label",
           "gemini3_label", "llama3_label")],
  method = "cohen",
  order  = c("gold_standard", "gpt5_label",
             "gemini3_label", "llama3_label")
)
#>          RaterA        RaterB method     value
#> 1 gold_standard    gpt5_label  cohen 0.8960499
#> 2 gold_standard gemini3_label  cohen 0.8960499
#> 3 gold_standard  llama3_label  cohen 0.3383743
#> 4    gpt5_label gemini3_label  cohen 0.7920998
#> 5    gpt5_label  llama3_label  cohen 0.3383743
#> 6 gemini3_label  llama3_label  cohen 0.2438563
```

## A — Assess stability

[`stab()`](https://casstai.github.io/craft-r/reference/stab.md) computes
reliability + validity for each model or prompt variant separately,
producing a tidy one-row-per-variant table:

``` r

stab(
  predictions = list(
    "GPT-5"     = demo$gpt5_label,
    "Gemini-3"  = demo$gemini3_label,
    "Llama-3.3" = demo$llama3_label
  ),
  gold = demo$gold_standard,
  reliability_method = "cohen",
  validity_metrics   = c("f1_macro", "f1_weighted", "mcc",
                         "balanced_accuracy")
)
#>     variant reliability_method reliability_value  f1_macro f1_weighted
#> 1     GPT-5              cohen         0.8960499 0.9480249   0.9600000
#> 2  Gemini-3              cohen         0.8960499 0.9480249   0.9600000
#> 3 Llama-3.3              cohen         0.3383743 0.6666667   0.7306667
#>   balanced_accuracy       mcc
#> 1         0.9480249 0.8960499
#> 2         0.9480249 0.8960499
#> 3         0.6860707 0.3445871
```

## F — Field audit and adjudication

[`audit()`](https://casstai.github.io/craft-r/reference/audit.md)
surfaces the rows that need human review by combining each LLM’s label
with its confidence:

``` r

# Pass text + rationales through so report() can quote them later
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
table(a$audit_status)
#> 
#>    agreement disagreement 
#>           46            4
```

The five rows lifted from the paper’s Table `tab:example` carry the
rationale text directly, so you can inspect why each annotator chose a
given label:

``` r

paper_rows <- demo[demo$source == "main.tex Table tab:example",
                   c("id", "text", "llama3_label",
                     "rationale_gpt5", "rationale_llama3")]
paper_rows
#>            id
#> 1 paper_ex_01
#> 2 paper_ex_02
#> 3 paper_ex_03
#> 4 paper_ex_04
#> 5 paper_ex_05
#>                                                                                                                                                                                                                                                 text
#> 1                                                                                                                       the irony of holding up environment budget negotiations over a rule to address air quality and climate change is nonsensical
#> 2 whats going on in texas is unconscionable people are dying bc of the power outage winter storm due to home fires carbon monoxide poisoning big impact on bipoc communities this was preventable blaming wind turbines amp renewables is ridiculous
#> 3                                                                                                                                                 tell the army corps the kxl pipeline endangers the health of families and kids deny the 404 permit
#> 4                                joe biden cant even earn our votes because his opinions are bought and paid for by the people supporting the policies we oppose fracking fossilfuels bigpharma biginsurance militaryindustrialcomplex to name a few
#> 5                                                                                                          RT @RBReich: Joe Manchin, who has repeatedly blocked efforts to combat climate change, collects 500,000 a year from coal stocks dividends
#>   llama3_label
#> 1      support
#> 2      support
#> 3      support
#> 4      support
#> 5     opposing
#>                                                                                              rationale_gpt5
#> 1                                      criticism of budget obstruction indicates support for climate policy
#> 2        defending renewables against blame for power outages indicates support for clean energy technology
#> 3                         fossil pipeline opposition is a proxy cue; denying permit supports climate action
#> 4 explicitly listing fracking and fossil fuels as policies to oppose signals support for climate mitigation
#> 5                        criticizing Manchin for blocking climate action signals support for climate policy
#>                                                 rationale_llama3
#> 1     post mentions climate change and policy with critical tone
#> 2                      post mentions renewables and storm impact
#> 3                       post calls for permit denial on pipeline
#> 4                 post lists fossil fuels among opposed policies
#> 5 proxy cues 'coal stocks' and 'blocks efforts' imply opposition
```

Notice the Manchin/Reich row (`paper_ex_05`): GPT-5 and Gemini-3
labelled it `support` with a context-aware rationale; Llama-3.3 labelled
it `opposing` after fixating on the surface phrases `coal stocks` and
`blocks efforts`. That is a real audit catch.

[`tau_sens()`](https://casstai.github.io/craft-r/reference/tau_sens.md)
shows how the audit categorization shifts as the confidence threshold
moves:

``` r

tau_sens(ann, thresholds = c(0.5, 0.55, 0.6, 0.7))
#>   threshold audit_status  n
#> 1      0.50    agreement 46
#> 2      0.50 disagreement  4
#> 3      0.55    agreement 46
#> 4      0.55 disagreement  4
#> 5      0.60    agreement 46
#> 6      0.60 disagreement  4
#> 7      0.70    agreement 46
#> 8      0.70 disagreement  4
```

## T — Translate to inference

The legislator-level dataset ships with the columns the DSL analysis
needs: `state`, outcomes (`sup`, `opp`), LLM predictions (`pred_sup`,
`pred_opp`), covariates, and the inclusion probability
(`cand_incl_prob_all`).

``` r

load(system.file("extdata", "data.rda", package = "craft"))
str(data)
#> 'data.frame':    2800 obs. of  11 variables:
#>  $ state             : chr  "LA" "ND" "HI" "IN" ...
#>  $ sup               : num  0.533 0.615 0.667 0.488 0.288 ...
#>  $ opp               : num  0.445 0.319 0.304 0.512 0.706 ...
#>  $ pred_sup          : num  0.586 0.623 0.752 0.414 0.237 ...
#>  $ pred_opp          : num  0.446 0.297 0.193 0.522 0.641 ...
#>  $ shor_ideo         : num  1.151 -0.569 -0.806 0.493 0.701 ...
#>  $ female            : int  0 0 0 0 0 0 1 0 0 0 ...
#>  $ senate            : int  1 0 0 0 0 0 0 0 0 0 ...
#>  $ per_mining        : num  1.621 3.146 0.788 0.33 0.958 ...
#>  $ perc_bchhigherE   : num  27.9 20.3 28.6 24.8 20.1 ...
#>  $ cand_incl_prob_all: num  0.212 0.24 0.144 0.486 0.47 ...
cat("Uncertainty residual: mean ",
    round(mean(1 - data$pred_sup - data$pred_opp), 3),
    ", median ",
    round(median(1 - data$pred_sup - data$pred_opp), 3),
    "\n", sep = "")
#> Uncertainty residual: mean 0.046, median 0.036
```

The implicit `1 - sup - opp` residual is small (mean ~4%), which matches
the climate-stance demonstration where most legislators have clearly
classifiable climate posts. **Practical consequence:** when uncertainty
is small, `dsl_cmp(sup ~ ...)` and `dsl_cmp(opp ~ ...)` produce
near-mirror-image coefficient estimates. When uncertainty is more
substantial, the two outcomes can have genuinely independent driver
patterns.

``` r

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
dsl_results
#>               term    model      estimate    std.error     conf.low
#> 1        shor_ideo Original -0.1391904077 0.0018595916 -0.142835207
#> 2       per_mining Original -0.0058696396 0.0008152092 -0.007467450
#> 3           female Original -0.0003596080 0.0033451043 -0.006916012
#> 4           senate Original -0.0002919763 0.0043861355 -0.008888802
#> 5  perc_bchhigherE Original  0.0041464226 0.0001875009  0.003778921
#> 6        shor_ideo      DSL -0.1414000000 0.0018000000 -0.145000000
#> 7       per_mining      DSL -0.0063000000 0.0007000000 -0.007700000
#> 8           female      DSL -0.0007000000 0.0035000000 -0.007600000
#> 9           senate      DSL -0.0006000000 0.0040000000 -0.008600000
#> 10 perc_bchhigherE      DSL  0.0041000000 0.0002000000  0.003700000
#>       conf.high      p.value
#> 1  -0.135545608 3.452998e-52
#> 2  -0.004271830 3.250399e-09
#> 3   0.006196796 9.148291e-01
#> 4   0.008304849 9.471965e-01
#> 5   0.004513924 3.797095e-27
#> 6  -0.137800000 0.000000e+00
#> 7  -0.004900000 0.000000e+00
#> 8   0.006200000 4.184000e-01
#> 9   0.007300000 4.382000e-01
#> 10  0.004400000 0.000000e+00
```

The opposing-stance model is the symmetric specification:

``` r

dsl_cmp(
  data    = data,
  formula = opp ~ shor_ideo + per_mining + female + senate + perc_bchhigherE,
  predicted_var = "opp",
  prediction    = "pred_opp",
  sample_prob   = "cand_incl_prob_all",
  fixed_effect  = "oneway",
  index   = "state",
  cluster = "state"
)
#> Cross-Fitting: 1/10..2/10..3/10..4/10..5/10..6/10..7/10..8/10..9/10..10/10..==================
#> DSL Specification:
#> ==================
#> Model:  felm (oneway)
#> Call:  opp ~ shor_ideo + per_mining + female + senate + perc_bchhigherE
#> Fixed Effects:  state
#> 
#> Predicted Variables:  opp
#> Prediction:  pred_opp
#> 
#> Number of Labeled Observations:  2800
#> Random Sampling for Labeling with Equal Probability:  No
#> (Sampling probabilities are defined in `sample_prob`)
#> 
#> =============
#> Coefficients:
#> =============
#>                 Estimate Std. Error CI Lower CI Upper p value    
#> shor_ideo         0.1432     0.0018   0.1397   0.1466  0.0000 ***
#> per_mining        0.0062     0.0009   0.0046   0.0079  0.0000 ***
#> female           -0.0026     0.0030  -0.0084   0.0032  0.1923    
#> senate            0.0036     0.0040  -0.0043   0.0116  0.1844    
#> perc_bchhigherE  -0.0046     0.0002  -0.0050  -0.0042  0.0000 ***
#> ---
#> Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 95% confidence intervals (CI) are reported.
#> Standard errors are clustered by state.
#>               term    model     estimate    std.error     conf.low    conf.high
#> 1        shor_ideo Original  0.140003770 0.0015974264  0.136872814  0.143134725
#> 2       per_mining Original  0.006476535 0.0007916722  0.004924857  0.008028213
#> 3           female Original  0.001881839 0.0033813818 -0.004745669  0.008509348
#> 4           senate Original -0.001497695 0.0036421583 -0.008636325  0.005640935
#> 5  perc_bchhigherE Original -0.004159863 0.0001971998 -0.004546375 -0.003773352
#> 6        shor_ideo      DSL  0.143200000 0.0018000000  0.139700000  0.146600000
#> 7       per_mining      DSL  0.006200000 0.0009000000  0.004600000  0.007900000
#> 8           female      DSL -0.002600000 0.0030000000 -0.008400000  0.003200000
#> 9           senate      DSL  0.003600000 0.0040000000 -0.004300000  0.011600000
#> 10 perc_bchhigherE      DSL -0.004600000 0.0002000000 -0.005000000 -0.004200000
#>         p.value
#> 1  1.602774e-55
#> 2  1.012191e-10
#> 3  5.803817e-01
#> 4  6.827109e-01
#> 5  3.091735e-26
#> 6  0.000000e+00
#> 7  0.000000e+00
#> 8  1.923000e-01
#> 9  1.844000e-01
#> 10 0.000000e+00
```

## Emit a reproducibility report

[`report()`](https://casstai.github.io/craft-r/reference/report.md)
writes a prose, methods-supplement-style document capturing the LLM,
version, prompt, threshold decisions, metrics, audit examples, and DSL
results. Output goes to whatever path you pass; relative paths resolve
against your current working directory. The shipped `prompt_dev4.txt` is
the actual dev4 codebook used in the climate-stance demonstration of the
CRAFT paper.

> **Long prompts.** In HTML output the prompt is rendered inside a
> collapsible `<details>` block — readers click to expand. In PDF output
> (where there is no toggle) the prompt is rendered as a wrapped
> verbatim block so the codebook is fully visible for transparency.

### Default: HTML in your working directory

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
  output      = "craft_report.html"      # writes to getwd()
)
```

### PDF for paper supplement (requires LaTeX)

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
  output      = "craft_report.pdf"
)
# First time only:
# tinytex::install_tinytex()
```

### Both formats side-by-side

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
  output      = "craft_report",          # no extension
  format      = "both"                   # writes .html AND .pdf
)
```

### Customizing the DSL table for non-climate studies

The report’s DSL table groups predictors as **Individual level** and
**District level** by default, with labels tuned to the climate-stance
demonstration. For other studies, attach `term_labels` and `term_groups`
attributes to the data frame returned by
[`dsl_cmp()`](https://casstai.github.io/craft-r/reference/dsl_cmp.md)
before passing it to
[`report()`](https://casstai.github.io/craft-r/reference/report.md):

``` r

my_dsl <- dsl_cmp(
  data    = my_data,
  formula = outcome ~ treatment + age + income + urban,
  predicted_var = "outcome",
  prediction    = "pred_outcome",
  sample_prob   = "incl_prob",
  fixed_effect  = "oneway",
  index   = "region",
  cluster = "region"
)

attr(my_dsl, "term_labels") <- c(
  treatment = "Treatment",
  age       = "Age",
  income    = "Household income",
  urban     = "Urban residence"
)
attr(my_dsl, "term_groups") <- list(
  "Primary"  = c("treatment"),
  "Controls" = c("age", "income", "urban")
)

report(..., dsl = my_dsl)
```

The rendered report contains prose narration of all CRAFT steps, the
prompt (toggle in HTML, expanded in PDF), a table of dual-track metrics
with one validity row per annotator, the stability table, 1-2
illustrative audit cases drawn from rows in your `audit` data frame that
carry `text` and `rationale_*` columns, and the grouped Original-vs-DSL
coefficient table.

## Where to go next

- [`vignette("getting-started")`](https://casstai.github.io/craft-r/articles/getting-started.md)
  — five-minute introduction.
- [`?reliab`](https://casstai.github.io/craft-r/reference/reliab.md) —
  list of reliability methods and when to use each.
- [`?report`](https://casstai.github.io/craft-r/reference/report.md) —
  full argument reference for the reproducibility report generator.
