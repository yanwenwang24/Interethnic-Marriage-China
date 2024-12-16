## ------------------------------------------------------------------------
##
## Script name: 11_sample.jl
## Purpose: Select samples for analysis
## Author: Yanwen Wang
## Date Created: 2024-10-06
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Select sample ---------------------------------------------------------

sample = restrict_sample(census)

# 2 Save sample -----------------------------------------------------------

Arrow.write("Data_cleaned/sample.arrow", sample)