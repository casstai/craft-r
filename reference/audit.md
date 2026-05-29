# Rationale audit (F step of CRAFT)

Given a data frame of annotations from two LLMs (with confidence and
rationale columns), surface the rows that need human review:
disagreements on the final label, and low-confidence agreements where
the threshold is debatable.

## Usage

``` r
audit(annotations, confidence_threshold = 0.6, low_threshold = 0.31)
```

## Arguments

- annotations:

  Data frame with at least these columns: `id`, `text`, `label_a`,
  `label_b`, `confidence_a`, `confidence_b`, optionally `rationale_a`,
  `rationale_b`.

- confidence_threshold:

  Numeric; rows where either confidence is below this value are flagged
  as `"low_conf_agreement"` when the labels match, or kept in
  `"disagreement"` when they differ.

- low_threshold:

  Below this value, agreements are treated as "agreement on uncertainty"
  rather than usable labels.

## Value

A data frame with an added `audit_status` column (one of `"agreement"`,
`"low_conf_agreement"`, `"uncertainty_agreement"`, `"disagreement"`).

## Examples

``` r
if (FALSE) { # \dontrun{
  a <- audit(annotations,
             confidence_threshold = 0.6,
             low_threshold = 0.31)
  table(a$audit_status)
} # }
```
