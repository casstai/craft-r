# Stability across prompts or models (A step of CRAFT)

Given a named list of predicted-label vectors (one per prompt or model
variant) plus a gold reference, compute reliability + validity for each
variant and stack the results into a tidy comparison table.

## Usage

``` r
stab(
  predictions,
  gold,
  reliability_method = "cohen",
  reliability_level = "nominal",
  validity_metrics = c("f1_macro", "mcc", "balanced_accuracy")
)
```

## Arguments

- predictions:

  A named list of prediction vectors, all of the same length. Names
  appear as the `variant` column of the returned table.

- gold:

  Gold-standard reference vector, same length as each prediction.

- reliability_method, reliability_level:

  Passed to
  [`reliab`](https://casstai.github.io/craft-r/reference/reliab.md).

- validity_metrics:

  Passed to
  [`valid`](https://casstai.github.io/craft-r/reference/valid.md).

## Value

A data frame with one row per variant.

## Examples

``` r
if (FALSE) { # \dontrun{
  stab(
    list("GPT-5" = labels$gpt5,
         "Gemini-3" = labels$gemini,
         "Llama-3.3" = labels$llama),
    gold = labels$human
  )
} # }
```
