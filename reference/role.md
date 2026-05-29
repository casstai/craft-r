# Construct role-task mapping (the C step of CRAFT)

Records how the researcher is conceptualizing the LLM (annotator / ML
system / silicon participant) and the task it is performing
(classification, clustering, simulation). Returns an object that
downstream functions (especially
[`report`](https://casstai.github.io/craft-r/reference/report.md))
consume.

## Usage

``` r
role(
  conception,
  task,
  gold = TRUE,
  prompt_type = c("zero-shot", "few-shot", "fine-tuned")
)
```

## Arguments

- conception:

  One of `"annotator"`, `"ml_system"`, `"silicon"`. Aliases:
  `"like-human annotator"` maps to `"annotator"`;
  `"machine learning system"` maps to `"ml_system"`;
  `"silicon participant"` maps to `"silicon"`.

- task:

  A short string describing the task (e.g. `"classify climate stance"`).

- gold:

  Logical: are gold-standard human labels available?

- prompt_type:

  One of `"zero-shot"`, `"few-shot"`, `"fine-tuned"`.

## Value

An object of class `craft_role` with components `conception`, `task`,
`gold`, `prompt_type`, and `suggested_metrics`.

## Details

Also enforces the role-task / metric mapping from Ko, Tai & Webb
Williams (Table 1 of the CRAFT paper): given a conception + task +
presence-of-gold-labels, it suggests which families of reliability and
validity metrics apply.

## Examples

``` r
role(conception = "annotator",
     task = "classify climate stance",
     gold = TRUE,
     prompt_type = "few-shot")
#> <craft role>
#>   Conception : annotator
#>   Task       : classify climate stance
#>   Gold labels: TRUE
#>   Prompt type: few-shot
#>   Suggested reliability methods: cohen, weighted, fleiss, kripp
#>   Suggested validity metrics  : precision, recall, f1_macro, f1_weighted, mcc, balanced_accuracy
#>   Reliability is central; validity against the gold subset is also reported.
```
