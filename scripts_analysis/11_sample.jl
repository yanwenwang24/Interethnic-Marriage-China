## ------------------------------------------------------------------------
##
## Purpose: Select samples for analysis
## Author: Yanwen Wang
## Date Created: 2024-10-06
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Select sample ---------------------------------------------------------

sample = restrict_sample!(census)

# Alternative sample (aged between 20 and 29)
# sample = restrict_sample_alt!(census) # Not ideal for being too selective

# 3 Save sample -----------------------------------------------------------

Arrow.write("data/processed/sample.arrow", sample)
