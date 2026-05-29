# Compare naive vs. design-based corrected estimates

Runs the same regression with and without DSL correction and returns a
tidy comparison data frame.

## Usage

``` r
dsl_cmp(
  data,
  formula,
  predicted_var,
  prediction,
  sample_prob,
  fixed_effect = NULL,
  index = NULL,
  cluster = NULL,
  ...
)
```

## Arguments

- data:

  Data frame.

- formula:

  Outcome formula. The LHS `predicted_var` is replaced by `prediction`
  for the naive fit.

- predicted_var, prediction, sample_prob, fixed_effect, index, cluster:

  See
  [`dsl_fit`](https://casstai.github.io/craft-r/reference/dsl_fit.md).

- ...:

  Forwarded to
  [`dsl::dsl()`](http://naokiegami.com/dsl/reference/dsl.md).

## Value

A long data frame with columns `term`, `model` (one of `"Original"` or
`"DSL"`), `estimate`, `std.error`, `conf.low`, `conf.high`, `p.value`.
