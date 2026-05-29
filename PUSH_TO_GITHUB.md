# Pushing `craft` to GitHub (GitHub Desktop walkthrough)

This is the point-and-click path using **GitHub Desktop** — no
terminal, no `git` commands. Works on a university laptop where you
can't necessarily install command-line tools.

> **Before you start**: if you plan to rename your GitHub handle
> (e.g. to `cassytai`), do that **now** at
> https://github.com/settings/admin **before** publishing the repo.
> Renaming after-the-fact breaks the URLs I've written into the
> package files.

Final username and target URLs (adjust everywhere if your handle is
different than `casstai`):

| Item | URL |
|---|---|
| GitHub repo | `https://github.com/casstai/craft-r` |
| Docs site (auto) | `https://casstai.github.io/craft-r/` |

## Step 1: Install GitHub Desktop (one-time)

Download from https://desktop.github.com and install. Sign in with the
GitHub account that you want the repo published under (`casstai` or
your renamed handle).

GitHub Desktop bundles its own copy of git, so you don't need to
install git separately on the university machine.

## Step 2: Turn the `craft/` folder into a local repository

1. Open **GitHub Desktop**.
2. Menu bar → **File → Add Local Repository...**
3. **Choose...** and navigate to:
   `/Users/yjt5154/Documents/Project/Pipeline/claude/craft`
4. GitHub Desktop will say:
   > *This directory does not appear to be a Git repository.
   > Would you like to create a repository here instead?*

   Click **`create a repository`** in that message (it's a link).

5. The "Create a Repository" dialog opens. Settings:
   - **Name**: `craft-r`
   - **Description**: `CRAFT framework for evaluating LLM-generated data`
   - **Local Path**: (already filled in)
   - **Initialize this repository with a README**: **leave UNCHECKED**
     (you already have `README.md`)
   - **Git ignore**: **None** (you already have `.gitignore`)
   - **License**: **None** (you already have `LICENSE`)
6. Click **Create Repository**.

Now GitHub Desktop shows all your files in the **Changes** tab on the
left (around 25-30 files), all staged.

## Step 3: First commit

In the bottom-left of GitHub Desktop:

- **Summary**: `Initial commit: craft v0.0.0.9000`
- **Description** (optional, paste this):
  ```
  Five-step CRAFT pipeline (Construct/Report/Assess/Field/Translate):
  - role() documents conception + task + gold + prompt
  - reliab() dispatches cohen/weighted/fleiss/kripp/icc/agree
  - valid() computes precision/recall/F1/MCC/f1_weighted/balanced accuracy
  - dual() bundles reliability + validity; accepts a single pred or
    a named list of preds for multi-annotator validity tables
  - stab() compares across prompts/models
  - audit()/disagree()/tau_sens() surface cases for human review
  - dsl_fit()/dsl_cmp() wrap design-based correction (Egami 2023)
  - report() emits a prose reproducibility report (HTML + PDF), with
    publication-quality grouped DSL coefficient tables
  ```

Click **Commit to main**.

## Step 4: Publish to GitHub

A **Publish repository** button appears at the top of GitHub Desktop.
Click it.

In the dialog:
- **Name**: `craft-r` (already filled)
- **Description**: (already filled)
- **Keep this code private**: **UNCHECK this** (you want a free
  pkgdown docs site, which requires a public repo for free GitHub
  Pages)
- **Organization**: leave as your personal account

Click **Publish Repository**.

After ~10 seconds, the repo is live at
`https://github.com/casstai/craft-r`. GitHub Desktop has a
**View on GitHub** button at the top — click it to open the repo in
your browser.

## Step 5: Enable GitHub Pages (one-time, ~30 seconds)

On the repo's GitHub page:

1. Click **Settings** (tab in the top navbar).
2. In the left sidebar, scroll down and click **Pages**.
3. Under **Build and deployment → Source**, choose **Deploy from a
   branch**.
4. Under **Branch**, the dropdown initially shows only `main`. You need
   to wait for the first pkgdown build to finish (Step 6) before
   `gh-pages` appears in this dropdown.

So leave this tab open and proceed to Step 6.

## Step 6: Watch the pkgdown workflow build the docs

1. Back on the repo page, click the **Actions** tab.
2. You'll see a workflow run titled "Initial commit: craft v0.0.0.9000"
   in progress.
3. Click it. The job is called **pkgdown**. It typically takes 4-8
   minutes the first time (installing R + all dependencies on a clean
   ubuntu runner).
4. When the workflow finishes (green checkmark), refresh the
   **Settings → Pages** tab from Step 5.
5. The **Branch** dropdown now shows `gh-pages`. Select it. Keep
   the path as `/ (root)`. Click **Save**.
6. The page reloads and shows
   > *Your site is live at https://casstai.github.io/craft-r/*

   Click that link. The first few minutes after Save you might see a
   404 while GitHub Pages provisions the site; try again in 2 minutes.

## Step 7: Sanity-check that anyone can install it

In any R session, on any machine:

```r
remotes::install_github("casstai/craft-r")
library(craft)
?role
```

If `?role` opens a help page, the world can now install your package.

## Future pushes

Once the repo exists, the workflow per change is:

1. Edit a file in RStudio. Save.
2. Switch to GitHub Desktop. New commits show in the **Changes** tab.
3. Type a one-line summary, click **Commit to main**.
4. Click **Push origin** (top of the GitHub Desktop window).
5. The pkgdown Action automatically rebuilds the docs site within ~5
   minutes.

## Tagging a release (after the Tuesday demo, not before)

In GitHub Desktop:
- Menu bar → **Repository → Create Release...** (or use the GitHub web
  UI: **Releases → Draft a new release**)
- Tag: `v0.0.0.9000`
- Title: `v0 draft for SSRI / SPSA presentation`
- Description: brief notes
- Click **Publish release**

## Pre-publish sanity check

Before you click **Publish repository** in Step 4, glance through the
**Changes** tab on the left side of GitHub Desktop. You **should** see:

| Path | Approx. size | Notes |
|---|---|---|
| `DESCRIPTION` | ~1 KB | Package metadata |
| `NAMESPACE` | <1 KB | Exported symbols |
| `LICENSE`, `LICENSE.md` | <1 KB each | MIT |
| `README.md` | ~3 KB | Repo landing page |
| `R/*.R` | ~30 KB total | 8 source files |
| `inst/extdata/craft_demo.csv` | ~8 KB | Synthetic demo data |
| `inst/extdata/data.rda` | ~170 KB | Synthetic legislator data |
| `inst/extdata/prompt_dev4.txt` | ~6 KB | Dev4 codebook |
| `inst/rmd/report_template.Rmd` | ~10 KB | Report template |
| `vignettes/*.Rmd` | ~20 KB total | Two user-facing vignettes |
| `tests/testthat/test-reliability.R` | ~3 KB | 23 expectations |
| `man/*.Rd` | varies | Auto-generated by `devtools::document()` |
| `_pkgdown.yml`, `.github/workflows/pkgdown.yaml` | small | Docs-site build |
| `craft.Rproj` | <1 KB | RStudio project file |
| `HOW_TO_TEST.md`, `PUSH_TO_GITHUB.md` | small | Developer docs (Rbuildignored) |

You should **not** see:

- API keys or credentials
- `craft_report.html`, `craft_report.pdf`, `craft_report.tex` — these
  are test renders from running `report()` interactively; they live
  in your working directory but are now in `.gitignore`
- `doc/`, `Meta/` folders — auto-generated by `devtools::build_vignettes()`,
  already gitignored
- `.Rcheck/`, `.Rhistory`, `.Rproj.user/`, `.DS_Store` — all gitignored

If you ever see something here that shouldn't be tracked, right-click
the file in GitHub Desktop and choose **Discard Changes**, then add a
matching pattern to `.gitignore` to prevent it from coming back.
