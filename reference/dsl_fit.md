# Design-based supervised learning correction (T step of CRAFT)

Wraps [`dsl::dsl()`](http://naokiegami.com/dsl/reference/dsl.md) so
misclassification uncertainty in the LLM-generated labels propagates
into the downstream regression estimates.

## Usage

``` r
dsl_fit(
  data,
  formula,
  predicted_var,
  prediction,
  sample_prob,
  model = "felm",
  fixed_effect = NULL,
  index = NULL,
  cluster = NULL,
  ...
)
```

## Arguments

- data:

  A data frame containing the predicted label column, the gold-label
  column (for the audited subset), the sample-inclusion probability
  column, and any covariates / fixed-effect indices / cluster
  identifiers used in `formula`.

- formula:

  A formula expression for the outcome model (e.g.
  `sup ~ ideology + female + senate + education`).

- predicted_var:

  Character name of the outcome column in `data`.

- prediction:

  Character name of the LLM-prediction column.

- sample_prob:

  Character name of the inclusion-probability column.

- model:

  Underlying regression model passed to
  [`dsl::dsl()`](http://naokiegami.com/dsl/reference/dsl.md). Default
  `"felm"` for fixed-effect linear models.

- fixed_effect, index, cluster:

  Passed through to
  [`dsl::dsl()`](http://naokiegami.com/dsl/reference/dsl.md).

- ...:

  Additional arguments forwarded to
  [`dsl::dsl()`](http://naokiegami.com/dsl/reference/dsl.md).

## Value

The object returned by
[`dsl::dsl()`](http://naokiegami.com/dsl/reference/dsl.md).

## Examples

``` r
if (FALSE) { # \dontrun{
  dsl_out <- dsl_fit(
    data    = legis_df,
    formula = sup ~ shor_ideo + per_mining + female + senate + perc_bchhigherE,
    predicted_var = "sup",
    prediction    = "pred_sup",
    sample_prob   = "cand_incl_prob_all",
    fixed_effect  = "oneway",
    index   = "state",
    cluster = "state"
  )
} # }
```
