# Validity metrics against a gold standard

Computes common validity metrics for categorical predictions against a
gold-standard reference. Returns a tidy one-row data frame so it
composes naturally with
[`reliab`](https://casstai.github.io/craft-r/reference/reliab.md) via
[`dual`](https://casstai.github.io/craft-r/reference/dual.md).

## Usage

``` r
valid(
  gold,
  pred,
  metrics = c("precision", "recall", "f1_macro", "f1_weighted", "accuracy",
    "balanced_accuracy", "mcc"),
  positive = NULL
)
```

## Arguments

- gold:

  A vector of gold-standard labels.

- pred:

  A vector of predicted labels, same length as `gold`.

- metrics:

  Character vector of metrics to compute. Default
  `c("precision", "recall", "f1_macro", "accuracy", "balanced_accuracy", "mcc")`.

- positive:

  Optional character: which level to treat as the positive class for
  binary-style precision/recall. If `NULL` (default), all reported
  metrics are macro-averaged.

## Value

A one-row data frame with one column per metric requested.

## Details

Supported metrics (researcher picks any subset via `metrics =`):

- `precision`:

  Macro-averaged precision (unweighted mean across classes).

- `recall`:

  Macro-averaged recall.

- `f1_macro`:

  Macro-averaged F1 (treats each class equally; useful when class
  balance is roughly equal or when minority-class performance matters).

- `f1_weighted`:

  Class-frequency-weighted F1 (weights each class's F1 by its support;
  closer to overall accuracy when classes are imbalanced).

- `accuracy`:

  Overall accuracy.

- `balanced_accuracy`:

  Mean of per-class recall.

- `mcc`:

  Matthews correlation coefficient, generalized to multi-class.

## Examples

``` r
if (FALSE) { # \dontrun{
  valid(gold = labels$human, pred = labels$gpt5)
} # }
```
