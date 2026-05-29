# Dual-track metrics: reliability + validity, side by side

Computes
[`reliab`](https://casstai.github.io/craft-r/reference/reliab.md) on
`ratings` and
[`valid`](https://casstai.github.io/craft-r/reference/valid.md) on
`(gold, pred)` and returns a list with the two tidy data frames. Use
when you want to report agreement and accuracy together (the C-R-A-F-T
*R* step).

## Usage

``` r
dual(
  ratings,
  gold,
  pred,
  pred_name = NULL,
  reliability_method = "auto",
  reliability_level = "nominal",
  reliability_weights = "equal",
  validity_metrics = c("precision", "recall", "f1_macro", "f1_weighted", "accuracy",
    "balanced_accuracy", "mcc")
)
```

## Arguments

- ratings:

  Data frame of rater columns for reliability.

- gold:

  Gold-standard label vector.

- pred:

  Either a single predicted-label vector, or a *named* list of
  predicted-label vectors (one entry per annotator:
  `list("GPT-5" = ..., "Gemini-3" = ..., "Llama-3.3" = ...)`). When a
  list is supplied, the returned `validity` table has one row per
  annotator with an additional `annotator` column.

- pred_name:

  Optional display name when `pred` is a single vector. Ignored when
  `pred` is a named list (the list names are used). Downstream renderers
  ([`report`](https://casstai.github.io/craft-r/reference/report.md))
  use this to label the validity table.

- reliability_method, reliability_level, reliability_weights:

  Passed through to
  [`reliab`](https://casstai.github.io/craft-r/reference/reliab.md).

- validity_metrics:

  Passed through to
  [`valid`](https://casstai.github.io/craft-r/reference/valid.md).

## Value

A list with elements `reliability`, `validity`, and `pred_name`. When
`pred` is a named list, `validity` is a stacked data frame with an
`annotator` column and `pred_name` is the character vector of annotator
names.
