# Pairwise reliability across all rater columns

Convenience wrapper that computes
[`reliab`](https://casstai.github.io/craft-r/reference/reliab.md) for
every pair of rater columns in `ratings` and returns a tidy long data
frame with one row per pair.

## Usage

``` r
reliab_pairs(
  ratings,
  method = "cohen",
  level = "nominal",
  weights = "equal",
  order = NULL,
  ...
)
```

## Arguments

- ratings:

  A data frame or matrix where each column is a rater (annotator /
  model) and each row is an item. Missing values are permitted by
  `kripp.alpha` but not by the others.

- method:

  One of `"cohen"`, `"weighted"`, `"fleiss"`, `"kripp"`, `"icc"`,
  `"agree"`. The default `"auto"` picks `"cohen"` for 2 raters + nominal
  data, `"weighted"` for 2 raters + ordinal data, `"fleiss"` for \>2
  raters + nominal data, `"kripp"` otherwise.

- level:

  Measurement level: `"nominal"`, `"ordinal"`, `"interval"`, or
  `"ratio"`. Used by `"auto"`, `"weighted"`, and `"kripp"`.

- weights:

  For `method = "weighted"`: either `"equal"` (linear) or `"squared"`
  (quadratic).

- order:

  Optional character vector specifying the display order of rater names.
  Useful for plotting.

- ...:

  Passed to the underlying `irr` function (e.g. `type`, `model` for
  ICC).

## Value

A data frame with columns `RaterA`, `RaterB`, `method`, `value`.
