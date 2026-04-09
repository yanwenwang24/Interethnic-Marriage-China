# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Replication package for "Three Decades of Interethnic Marriage in China: Ethnic Boundaries, Educational Sorting, and Status Exchange" (Wang & Mu). Analyzes interethnic marriage patterns using China's Census data (1982, 1990, 2000, 2010) with log-linear models and the Exchange Index methodology (Xie & Dong, 2021).

## Language and Dependencies

Analysis code is written in **Julia**. Visualization is in **R** (ggplot2).

Julia packages:

- **Data**: DataFrames, DataFramesMeta, Arrow, CategoricalArrays, FreqTables
- **Statistics/Models**: GLM, StatsBase, Distributions, ProportionalFitting, LinearAlgebra
- **R interop**: RCall (uses R's `MatchIt` package for exact matching via `@rget`/`R""` macros)

R packages required: `tidyverse`, `arrow`, `scales`, `MatchIt`.

## Running the Code

Data cleaning (run from `scripts_tidy/`):

```julia
include("scripts_tidy/00_tidy_main.jl")
```

This master file loads packages, dictionaries, functions, then runs `01_tidy_82.jl` through `05_tidy_join.jl` sequentially.

Analysis (run from project root after `10_import.jl` sets up the environment):

```julia
include("scripts_analysis/10_import.jl")  # loads packages, data, dictionaries, functions
include("scripts_analysis/11_sample.jl")  # restricts sample
# Then run individual analysis scripts (12-19)
```

Scripts must be run in numeric order — each depends on variables created by prior scripts. Analysis scripts export plot-ready DataFrames as Arrow files to `data/visualization/`.

Visualization (run from project root after Arrow files are generated):

```r
source("scripts_visualize/00_main.R")
```

This sources `theme.R` (shared theme/palettes) then each `fig*.R` script, generating PDF figures in `figures/`.

## Architecture

### Data Pipeline

1. **`scripts_tidy/`** — Cleans raw IPUMS census data (1982, 1990, 2000) and 2010 census into Arrow format
   - `dictionaries.jl`: Mapping tables for ethnicity (56 groups → 9 ethnic groups + Han), regions (province codes → 6 regions), education, marital status
   - `functions.jl`: Household matching (`create_parent_matches`, `create_children_matches`), entropy calculation
   - Output: `data/processed/census.arrow`, `data/processed/sample.arrow`

2. **`scripts_analysis/`** — All analytical scripts (Julia)
   - `functions.jl`: Core analysis functions (sample restriction, log-linear model utilities, Exchange Index calculation, exact matching via R)
   - `10_import.jl`: Entry point — loads all packages, dictionaries, functions, and data
   - `11_sample.jl`: Applies sample restrictions (married women aged 25-34 with non-missing ethnicity/education)
   - `12-13`: Descriptive trends and ethnic composition; export Arrow files for visualization
   - `14_loglinear_ethngrp.jl` + `14.1-14.7`: Log-linear models of intermarriage by ethnic group (national + 6 regions)
   - `15_loglinear_edu.jl` + `15.1-15.7`: Log-linear models with education interactions (national + 6 regions)
   - `16_exchange_index_ethngrp.jl` + `16.1-16.6`: Exchange Index by ethnic group (national + 6 regions)
   - `17_exchange_index_ethnicity.jl`: Exchange Index for individual Southern ethnicities
   - `18.1-18.2`: Exchange Index split by preferential birth policy status
   - `19_exchange_index_by_tertile.jl`: Exchange Index by education tertile

3. **`scripts_visualize/`** — All visualization scripts (R/ggplot2)
   - `00_main.R`: Orchestrator — loads packages and sources all figure scripts
   - `theme.R`: Shared custom theme (`theme_intermarriage`), color palettes, factor orderings
   - `fig1`–`fig7`: One script per figure, reading Arrow data from `data/visualization/`
   - Output: PDF figures in `figures/`

### Key Ethnic Group Classification

China's 56 ethnicities are collapsed into 9 groups: Han, Hui, Kazakh, Korean, Manchu, Mongolian, Southern, Tibetan, Uyghur. The "Southern" group aggregates ~30 smaller southern minorities. Mapping defined in `dictionaries.jl` (`ethngrp_dict1` by numeric code, `ethngrp_dict2` by Chinese name).

### Regional Analysis Pattern

Many analyses (14.x, 15.x, 16.x) repeat the national-level script for 6 regions: Huabei, Dongbei, Huadong, Zhongnan, Xinan, Xibei. These scripts are structurally identical to their parent but filter data by region.

### Data Format

Processed data is stored as Arrow files. Raw census data (`data/raw/`) is from IPUMS International (2010 census cannot be redistributed). Both `data/` and `figures/` are gitignored.

## Code Conventions

- Script headers follow a standard template with Purpose, Author, Date Created, Email
- DataFramesMeta `@chain` macros are used extensively for data manipulation pipelines
- Log-linear models use GLM's `glm(..., Poisson())` on contingency tables (not individual-level data)
- The Exchange Index workflow: `retrieve_sample` → `matchit` (R interop) → `calculate_EI` → `extract_p`
- Variables use `_sp` suffix for spouse attributes, `_f`/`_m` for female/male attributes
