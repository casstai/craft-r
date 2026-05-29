# How to install, test, and check `craft`

This walkthrough is for you and any coauthor. Everything here runs from
the package root: `/Users/yjt5154/Documents/Project/Pipeline/claude/craft`
(or wherever the package lives on your coauthor's machine).

## 0. Function cheat-sheet (12 total)

| Function | CRAFT step | What it does |
|---|---|---|
| `role()` | C | Documents conception + task + gold + prompt_type. Returns a `craft_role` object. |
| `reliab()` | R | Dispatches one inter-rater reliability metric (`cohen`, `weighted`, `fleiss`, `kripp`, `icc`, `agree`, or `auto`). |
| `reliab_pairs()` | R | Pairwise reliability for every column-pair (useful for kappa heatmaps). |
| `valid()` | R | Validity vs. gold: precision, recall, f1_macro, f1_weighted, accuracy, balanced accuracy, MCC. |
| `dual()` | R | Bundles `reliab()` + `valid()` into one call. |
| `stab()` | A | Cross-prompt or cross-model stability table. |
| `audit()` | F | Tags each row as agreement / low-conf agreement / uncertainty / disagreement. |
| `disagree()` | F | Subsets `audit()` output to rows needing human review. |
| `tau_sens()` | F | Confidence-threshold sensitivity across a grid of taus. |
| `dsl_fit()` | T | Wraps `dsl::dsl()` for design-based corrected regression. |
| `dsl_cmp()` | T | Runs naive `lfe::felm` and DSL-corrected fit side-by-side; returns a tidy comparison. |
| `report()` | -- | Emits a reproducibility Rmd capturing role + LLM + prompt + metrics + audit + DSL. |

Help on any function: `?role`, `?reliab`, etc.

## 1. One-time setup (you and coauthor)

### A. Open the package as an RStudio project

The `craft.Rproj` file in the package root is what makes RStudio
"package-aware" (it enables the Build tab, the Test button, etc.).

**Easiest way**: in Finder/Explorer, **double-click** `craft.Rproj`.
RStudio opens with the project loaded.

**Alternative (from inside RStudio)**:
1. RStudio menu → **File → Open Project...**
2. Browse to `/Users/yjt5154/Documents/Project/Pipeline/claude/craft/`
3. Select `craft.Rproj` and click Open.

You'll know it worked when:
- The RStudio window title shows `craft - RStudio`.
- A **Build** tab appears in the top-right pane (next to Environment,
  History, etc.).

You only do this once per machine. Next time, click `craft` under
RStudio's "Recent Projects" menu.

### B. Install dependencies (one-time)

In the RStudio Console:

```r
install.packages("devtools")

install.packages(c(
  "irr",         # inter-rater reliability metrics
  "irrCAC",      # listed in Suggests; safe to skip if it errors
  "dplyr",
  "tidyr",
  "ggplot2",
  "rmarkdown",
  "knitr",
  "yaml",
  "rlang",
  "testthat"
))

# DSL is used by the T step (dsl_fit / dsl_cmp)
remotes::install_github("naoki-egami/dsl")
```

> If `irrCAC` fails to install on your machine, that is fine for v0 -
> nothing in v0 actually uses it. The Imports line in DESCRIPTION can
> be tightened later.

## 2. Load the package without installing (dev mode)

In the RStudio Console:

```r
library(devtools)
load_all()
```

Or use the keyboard shortcut **Cmd+Shift+L** (Mac) / **Ctrl+Shift+L**
(Windows/Linux) — same thing.

`load_all()` exposes every function (`role`, `reliab`, `valid`, ...)
as if the package were installed. **Edit a file in `R/` and re-run
`load_all()`** — that's the fast inner-loop workflow.

Verify it worked:

```r
role("annotator", "test", gold = TRUE, prompt_type = "few-shot")
?role                   # help page should open in the Help pane
```

If `?role` opens a help page, the package is loaded correctly.

## 3. Run the tests

```r
devtools::test()
```

Or **Cmd+Shift+T** / **Ctrl+Shift+T** in RStudio. You can also click
the **Build → Test Package** button in the Build tab.

Expected output:

```
i Testing craft
v |         16 | reliability [0.1s]

== Results ===========================================
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 16 ]
```

To run a single test file:

```r
testthat::test_file("tests/testthat/test-reliability.R")
```

## 4. Full `R CMD check` (use before pushing or releasing)

`R CMD check` is the gold-standard package-quality check. It runs
tests, checks documentation, verifies the package builds, and flags
non-portable code.

```r
devtools::check()
```

Or **Cmd+Shift+E** / **Ctrl+Shift+E** in RStudio, or click
**Build → Check Package**.

Expected outcome: 0 errors, 0 warnings, possibly a few NOTEs (e.g.,
"installed size larger than X MB" if `inst/extdata` is big — fine for
a v0).

If you see an ERROR or WARNING, the message usually tells you the
fix. Common ones:

- **"no visible global function definition for X"** → add
  `importFrom(packageName, X)` to NAMESPACE.
- **"no visible binding for global variable X"** → almost always a
  dplyr column name; add `utils::globalVariables(c("X"))` to a file
  like `R/zzz.R` (we can add this later).
- **missing documentation** → run `devtools::document()` to regenerate
  `man/*.Rd` from roxygen comments.

## 5. Install locally (so you can `library(craft)` from anywhere)

```r
devtools::install()
```

After that:

```r
library(craft)
```

works in any R session.

## 6. Build the vignette

```r
devtools::build_vignettes()
```

The built HTML lands in `doc/`. Open it in your browser to see the
walkthrough.

## 7. Quick sanity script (no devtools needed)

If your coauthor doesn't want to install devtools, this also works:

```r
setwd("/path/to/craft")
library(irr)
for (f in list.files("R", "\\.R$", full.names = TRUE)) source(f)

# Try a function
role("annotator", "classify climate stance", gold = TRUE,
     prompt_type = "few-shot")
```

## 8. Where to look when something breaks

- `R/<step>.R` — the source for each CRAFT step
- `tests/testthat/test-reliability.R` — the test suite (add more here)
- `inst/rmd/report_template.Rmd` — the report template the
  `report()` function renders
- `vignettes/craft-walkthrough.Rmd` — the long worked example
- `vignettes/getting-started.Rmd` — the 5-minute tour (when added)

## Troubleshooting checklist

| Symptom | Likely fix |
|---|---|
| `there is no package called 'craft'` | Use `devtools::load_all()` from the package root, or `devtools::install()` first. |
| `could not find function "reliab"` | You ran `library(craft)` before installing. Run `load_all()` instead. |
| `Package 'dsl' is required` | `remotes::install_github("naoki-egami/dsl")` |
| `installation of package 'irrCAC' had non-zero exit status` | Skip for now — `irrCAC` is listed in Suggests/Imports but not actually used in v0. We can drop it from DESCRIPTION if it's persistent. |
| Tests run but render fails | `rmarkdown` and/or LaTeX (for PDF). For HTML output only, `rmarkdown` alone is enough. |

## Pushing to GitHub

See `PUSH_TO_GITHUB.md` for the exact commands.
