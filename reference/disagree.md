# Summarize cases needing adjudication

Returns just the rows of `audit` that require human review, optionally
restricted to one `audit_status` category.

## Usage

``` r
disagree(audit, status = c("disagreement", "low_conf_agreement"))
```

## Arguments

- audit:

  A data frame produced by
  [`audit`](https://casstai.github.io/craft-r/reference/audit.md).

- status:

  Which status(es) to return. Default returns disagreements and
  low-confidence agreements.

## Value

A subset of `audit`.
