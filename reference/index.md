# Package index

## C - Construct role-task

Document how the LLM is being used and which metric family applies.

- [`role()`](https://casstai.github.io/craft-r/reference/role.md) :
  Construct role-task mapping (the C step of CRAFT)

## R - Report dual-track metrics

Reliability (six methods) paired with validity (six metrics).

- [`reliab()`](https://casstai.github.io/craft-r/reference/reliab.md) :
  Inter-rater reliability (R step of CRAFT)
- [`reliab_pairs()`](https://casstai.github.io/craft-r/reference/reliab_pairs.md)
  : Pairwise reliability across all rater columns
- [`valid()`](https://casstai.github.io/craft-r/reference/valid.md) :
  Validity metrics against a gold standard
- [`dual()`](https://casstai.github.io/craft-r/reference/dual.md) :
  Dual-track metrics: reliability + validity, side by side

## A - Assess stability

Cross-prompt and cross-model comparison.

- [`stab()`](https://casstai.github.io/craft-r/reference/stab.md) :
  Stability across prompts or models (A step of CRAFT)

## F - Field audit

Surface disagreements and low-confidence agreements; threshold
sensitivity.

- [`audit()`](https://casstai.github.io/craft-r/reference/audit.md) :
  Rationale audit (F step of CRAFT)
- [`disagree()`](https://casstai.github.io/craft-r/reference/disagree.md)
  : Summarize cases needing adjudication
- [`tau_sens()`](https://casstai.github.io/craft-r/reference/tau_sens.md)
  : Sensitivity of label coverage to the confidence threshold

## T - Translate to inference

Design-based corrected regression so misclassification uncertainty
propagates.

- [`dsl_fit()`](https://casstai.github.io/craft-r/reference/dsl_fit.md)
  : Design-based supervised learning correction (T step of CRAFT)
- [`dsl_cmp()`](https://casstai.github.io/craft-r/reference/dsl_cmp.md)
  : Compare naive vs. design-based corrected estimates

## Reproducibility report

- [`report()`](https://casstai.github.io/craft-r/reference/report.md) :
  Generate a CRAFT reproducibility report
