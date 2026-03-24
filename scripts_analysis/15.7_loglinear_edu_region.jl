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

odds_ratio_df = vcat(
    odds_ratio_Huabei,
    odds_ratio_Dongbei,
    odds_ratio_Huadong,
    odds_ratio_Zhongnan,
    odds_ratio_Xinan,
    odds_ratio_Xibei
)

@transform!(odds_ratio_df, :region = categorical(:region, levels=["North", "Northeast", "East", "South Central", "Southwest", "Northwest"]))

Arrow.write("data/visualization/fig7_odds_by_edu_region.arrow", odds_ratio_df)

# Expotentiate the coefficients
@chain odds_ratio_df begin
    @transform(:ratio = round.(exp.(:coefficient) * 1000, digits=2))
    @transform(
        :coefficient = round.(:coefficient, digits=2),
        :std_error = round.(:std_error, digits=2),
    )
    @select(:region, :ethngrp, :edu, :coefficient, :std_error, :ratio)
    println
end