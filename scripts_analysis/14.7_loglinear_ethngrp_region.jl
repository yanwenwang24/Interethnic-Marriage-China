## ------------------------------------------------------------------------
##
## Purpose: Generate graphs by region
## Author: Yanwen Wang
## Date Created: 2024-11-15
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Ethnic boundaries -----------------------------------------------------

odds_ratio_df = vcat(
    odds_ratio_Huabei,
    odds_ratio_Dongbei,
    odds_ratio_Huadong,
    odds_ratio_Zhongnan,
    odds_ratio_Xinan,
    odds_ratio_Xibei
)

@transform!(
    odds_ratio_df,
    :region = categorical(
        :region,
        levels=["North", "Northeast", "East", "South Central", "Southwest", "Northwest"]
    )
)

Arrow.write("data/visualization/fig5_odds_by_ethngrp_region.arrow", odds_ratio_df)
