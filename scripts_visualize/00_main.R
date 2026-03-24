## ------------------------------------------------------------------------
##
## Purpose: Generate all figures for the interethnic marriage paper
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

library(tidyverse)
library(arrow)
library(scales)

# Load shared theme and palettes
source("scripts_visualize/theme.R")

# Generate each figure
source("scripts_visualize/fig1_trends_by_ethngrp.R")
source("scripts_visualize/fig2_trends_by_edu.R")
source("scripts_visualize/fig3_edu_comp.R")
source("scripts_visualize/fig4_odds_by_ethngrp.R")
source("scripts_visualize/fig5_odds_by_ethngrp_region.R")
source("scripts_visualize/fig6_odds_by_edu.R")
source("scripts_visualize/fig7_odds_by_edu_region.R")

message("All figures generated successfully.")
