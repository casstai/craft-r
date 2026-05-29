# craft

> A CRAFT pipeline for evaluating LLM-generated data in political and
> social science research.

`craft` is an R package that operationalizes the **C-R-A-F-T** framework
(Ko, Tai, and Webb Williams) for using large language models (LLMs) as
data-generation tools. It does not call LLM APIs itself in v0; it takes the outputs you
already have — labels, confidences, rationales — and walks them
through the five steps.

| Step | Function | What it does |
|---|---|---|
| **C**onstruct | `role()` | Documents how the LLM is being used and which metric family applies. |
| **R**eport | `reliab()`, `reliab_pairs()`, `valid()`, `dual()` | Reliability (Cohen's $\kappa$, weighted $\kappa$, Fleiss', Krippendorff's $\alpha$, ICC, percent agreement) paired with validity (precision, recall, F1, accuracy, balanced accuracy, MCC). |
| **A**ssess | `stab()` | Cross-prompt / cross-model stability comparison. |
| **F**ield audit | `audit()`, `disagree()`, `tau_sens()` | Surfaces disagreements + low-confidence agreements; confidence-threshold sensitivity. |
| **T**ranslate | `dsl_fit()`, `dsl_cmp()` | DSL correction so misclassification uncertainty propagates into inference. |
| **Report** | `report()` | Emits a reproducibility Rmd capturing LLM, version, prompt, metrics, thresholds, audit, DSL. |

12 exported functions total. All short and verb-like.

## Installation

```r
# install.packages("remotes")
remotes::install_github("casstai/craft-r")
```

The `dsl` dependency (Egami et al. 2023):

```r
remotes::install_github("naoki-egami/dsl")
```

## Quick start

```r
library(craft)

# C: document the role-task
rt <- role("annotator", "classify climate stance",
           gold = TRUE, prompt_type = "few-shot")

# R: dual-track metrics
dual(ratings = data.frame(human = h, llm = g),
     gold = h, pred = g,
     reliability_method = "cohen")

# A: cross-model stability
stab(list("GPT-5" = g, "Gemini-3" = gem, "Llama-3.3" = llama),
     gold = h)

# F: audit
a <- audit(ann, confidence_threshold = 0.55, low_threshold = 0.31)
disagree(a)
tau_sens(ann, thresholds = c(0.5, 0.55, 0.6, 0.7))

# T: DSL correction
dsl_cmp(data = legis_df,
        formula = sup ~ shor_ideo + per_mining + female + senate + perc_bchhigherE,
        predicted_var = "sup",
        prediction    = "pred_sup",
        sample_prob   = "cand_incl_prob_all",
        fixed_effect  = "oneway",
        index = "state", cluster = "state")

# Emit the reproducibility report
report(role_task   = rt,
             llm         = "GPT-5",
             version     = "gpt-5-2025-09-15",
             prompt_path = "prompts/dev4.txt",
             output      = "craft_report.html")
```

## Worked example

See `vignettes/getting-started.Rmd` (5-minute tour) and
`vignettes/craft-walkthrough.Rmd` (full climate-stance example).

## Citing

> Ko, H., Tai, Y. C., & Webb Williams, N. (2026). Can We Trust
> LLM-Generated Data? The CRAFT Framework for Measurement and Inference
> in Political Science.

> Tai, Y. C., & Ko, H. (2026). craft: A CRAFT Pipeline for Evaluating
> LLM-Generated Data. R package version 0.0.0.9000.

## License

MIT. See `LICENSE.md`.
