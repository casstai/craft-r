# Inter-rater reliability (R step of CRAFT)

Unified interface to common inter-rater reliability metrics, so the
researcher can pick a method appropriate to their data. The `method`
argument chooses among:

## Usage

``` r
reliab(
  ratings,
  method = c("auto", "cohen", "weighted", "fleiss", "kripp", "icc", "agree"),
  level = c("nominal", "ordinal", "interval", "ratio"),
  weights = c("equal", "squared"),
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

- ...:

  Passed to the underlying `irr` function (e.g. `type`, `model` for
  ICC).

## Value

A one-row data frame.

## Details

- `"cohen"`:

  Cohen's kappa. Two raters, nominal data. Wraps
  `irr::kappa2(weight = "unweighted")`.

- `"weighted"`:

  Weighted Cohen's kappa. Two raters, ordinal data. Wraps
  [`irr::kappa2()`](https://rdrr.io/pkg/irr/man/kappa2.html) with
  `weight = "equal"` (linear) or `"squared"` (quadratic) via the
  `weights` argument.

- `"fleiss"`:

  Fleiss' kappa. More than two raters, nominal data. Wraps
  [`irr::kappam.fleiss()`](https://rdrr.io/pkg/irr/man/kappam.fleiss.html).

- `"kripp"`:

  Krippendorff's alpha. Any number of raters, missing values allowed,
  any measurement level. Wraps
  [`irr::kripp.alpha()`](https://rdrr.io/pkg/irr/man/kripp.alpha.html)
  with `method` controlled by the `level` argument (`"nominal"`,
  `"ordinal"`, `"interval"`, `"ratio"`).

- `"icc"`:

  Intra-class correlation. Continuous ratings. Wraps
  [`irr::icc()`](https://rdrr.io/pkg/irr/man/icc.html). Use `type` and
  `model` arguments for the ICC form.

- `"agree"`:

  Simple percent agreement. Wraps
  [`irr::agree()`](https://rdrr.io/pkg/irr/man/agree.html). Reported
  alongside other metrics; not a substitute for chance-corrected
  agreement.

All methods return a tidy one-row data frame with columns `method`,
`value`, `n_raters`, `n_items`, and any method-specific fields (e.g.,
`p_value`, `ci_lower`, `ci_upper` when available).

## Examples

``` r
if (FALSE) { # \dontrun{
  ratings <- data.frame(
    human  = c("sup", "opp", "sup", "non"),
    gpt5   = c("sup", "opp", "sup", "non"),
    gemini = c("sup", "opp", "non", "non")
  )
  reliab(ratings, method = "kripp", level = "nominal")
  reliab(ratings[, 1:2], method = "cohen")
  reliab(ratings, method = "fleiss")
} # }
```
