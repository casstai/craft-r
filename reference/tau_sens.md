# Sensitivity of label coverage to the confidence threshold

Recomputes the audit categorization across a grid of confidence
thresholds so the researcher can see how many cases drop into
"low_conf_agreement" or "uncertainty" at each tau.

## Usage

``` r
tau_sens(
  annotations,
  thresholds = c(0.5, 0.55, 0.6, 0.7),
  low_threshold = 0.31
)
```

## Arguments

- annotations:

  As in [`audit`](https://casstai.github.io/craft-r/reference/audit.md).

- thresholds:

  Numeric vector of confidence thresholds to scan (e.g.
  `c(0.5, 0.55, 0.6, 0.7)`).

- low_threshold:

  Passed to
  [`audit`](https://casstai.github.io/craft-r/reference/audit.md).

## Value

A long data frame: one row per (threshold, audit_status) with column
`n`.
