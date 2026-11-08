# Microeconometrics — Group Project

Coursework completed jointly by **Zoe Di Lieto, Yael Brianzi, and Clément Simon**.

This repository collects our code, datasets, and saved results for **Problem Sets 2 and 3**. The project applies causal inference methods in Stata and R, covering difference-in-differences, heterogeneous treatment effects, and regression discontinuity designs. Exercise answers and interpretations are included as comments in the scripts.

## Project overview

### Problem Set 2 — Divorce laws and treatment effect heterogeneity

**Exercise 1 (Stata)** studies unilateral divorce laws and US divorce rates. The analysis includes population-weighted descriptive trends, a two-period difference-in-differences comparison, two-way fixed effects with state-specific trends, and simulations illustrating problems with staggered adoption and heterogeneous effects. It also implements TWFE weight diagnostics, a Goodman–Bacon decomposition, conventional event studies, and Sun–Abraham event studies.

**Exercise 2 (R)** uses expanded county-level data to study heterogeneity in the effect of unilateral divorce laws. A causal forest models the change in divorce rates between 1968 and 1978. The analysis examines average and conditional treatment effects, best linear projections, treatment effect rankings, variable importance, and the comparison between honest and dishonest forests.

### Problem Set 3 — Regression discontinuity designs

**Exercise 1 (Stata)** examines the effect of electing an Islamic mayor on female high school completion using the Islamic party's 1994 vote margin as the running variable. It includes treatment assignment plots, covariate balance checks, density and placebo tests, local linear and polynomial estimates, and sensitivity to bandwidth and kernel choices.

**Exercise 2 (Stata)** studies mobile phone coverage and electoral fraud using distance to a coverage boundary. The script examines the first stage and estimates a fuzzy RD specification with instrumental variables and segment fixed effects, reporting results for all regions and separately for the Southeast and Northwest.

## Repository structure

```text
.
├── README.md
├── PS2_DiLieto_brianzi_Simon/
│   ├── PS2_ex1_Brianzi_DiLieto_Simon.do
│   ├── PS2_ex2_Brianzi_DiLieto_Simon.R
│   ├── pset_2.csv / pset_2.dta
│   ├── expanded_data.csv / expanded_data.dta
│   ├── TABLE_1.xlsx
│   └── Saved figures (.png)
└── PS3_Brianzi_DiLieto_Simon/
    ├── PS3_Brianzi_DiLieto_Simon.do
    ├── Table1.csv
    ├── table2_replication.xlsx
    ├── point_j_local_linear.xls
    ├── poly_regression_results.xls
    └── Saved figures (.png and .pdf)
```

The figure entries above summarize multiple files rather than literal filenames.

## Software and dependencies

### Stata

A licensed Stata installation is required for the `.do` files. Install the community-contributed packages used by the relevant problem set:

```stata
* Problem Set 2
ssc install ftools
ssc install require
ssc install reghdfe
ssc install twowayfeweights
ssc install bacondecomp
ssc install coefplot
ssc install avar
ssc install eventstudyinteract

* Problem Set 3
ssc install rdrobust
ssc install rddensity
ssc install lpdensity
ssc install outreg2
```

### R

Install the packages loaded by the PS2 R script:

```r
install.packages(c("dplyr", "haven", "grf"))
```

The repository does not specify software or package versions.

## Running the analyses

The scripts retain the original group members' local paths. Update these before running them on another computer.

### PS2, Exercise 1

1. Open `PS2_DiLieto_brianzi_Simon/PS2_ex1_Brianzi_DiLieto_Simon.do` in Stata.
2. Replace the username-dependent path block with a path to your local PS2 folder, including the final slash. For example:

   ```stata
   global filepath "/absolute/path/to/Micrometrics project/PS2_DiLieto_brianzi_Simon/"
   cd "$filepath"
   ```

3. Run the do-file. Both `pset_2.csv` and `pset_2.dta` are included. Most figures are written to `$filepath`; `TABLE_1.xlsx` is written to Stata's current working directory.

### PS2, Exercise 2

1. Open `PS2_DiLieto_brianzi_Simon/PS2_ex2_Brianzi_DiLieto_Simon.R` in R or RStudio.
2. Replace the username-dependent path block with your PS2 folder and update the hard-coded `read.csv()` call to use it:

   ```r
   filepath <- "/absolute/path/to/Micrometrics project/PS2_DiLieto_brianzi_Simon/"
   auto <- read.csv(file.path(filepath, "expanded_data.csv"), sep = ",")
   ```

3. Before the first use of `cate_hat` (the CATE histogram), add:

   ```r
   cate_hat <- predict(cf)$predictions
   ```

4. Run the script. Plots are displayed in R's graphics device; the script does not explicitly save them to the PNG filenames included in this repository.

### PS3

1. Obtain **`pset_3.dta`** and **`fraud_pcenter_final.dta`** from the original course or replication materials. These input datasets are referenced by the code but **are not included in this repository**.
2. Place both datasets in your local PS3 folder.
3. Open `PS3_Brianzi_DiLieto_Simon/PS3_Brianzi_DiLieto_Simon.do` and replace the username-dependent path block with:

   ```stata
   global filepath "/absolute/path/to/Micrometrics project/PS3_Brianzi_DiLieto_Simon/"
   ```

4. Run the do-file. Its existing `cd "$filepath"` command sets the directory used for data inputs and exported results.

Exports that use Stata's `replace` option overwrite existing files with the same names.

## Saved results

| Folder | Selected outputs |
| --- | --- |
| PS2 | `fig1.png` and `fig2.png`: divorce rate trends; `TABLE_1.xlsx`: two-period DiD table; `bacon_decomp.png`: decomposition plot |
| PS2 | `event_study.png` and `event_study_SA_1.png`–`event_study_SA_3.png`: conventional and Sun–Abraham event studies |
| PS2 | `ex.2_*.png` and `ex-2_b_(iii).png`: saved causal forest and heterogeneity figures |
| PS3 | `Table1.csv` and `Graph_1.pdf`: covariate balance checks; `Graph_2.pdf`: running variable density and histogram |
| PS3 | `rdplot_T_X.png`, `rdplot_Y_X.png`, and `graph_3.png`: treatment assignment, outcome RD, and bandwidth sensitivity plots |
| PS3 | `poly_regression_results.xls` and `point_j_local_linear.xls`: regression tables |
| PS3 | `regression_function_fit.png` and `table2_replication.xlsx`: coverage first-stage plot and fraud estimates |

## Reproducibility notes

This repository preserves the coursework scripts and saved outputs. The setup instructions above document adjustments needed for a fresh run; they have not been applied to the original scripts, and the analyses have not been rerun as part of preparing this README.

In addition to the missing PS3 datasets and the undefined `cate_hat` object in R, the PS3 density-plot section uses local macros `h_l` and `h_r` before defining them, after defining `h_left` and `h_right`. Align these names and their signs before running that section. The R train/evaluation split also has no explicit seed immediately before `sample()`, so its results can vary with the random state.

The saved outputs can be viewed independently of the software setup. Their presence does not establish that every script currently runs from start to finish in a clean session.

## Authorship

This is a **group project by Di Lieto, Brianzi, and Simon**. The analyses, code, and interpretations should be credited to the group collectively.
