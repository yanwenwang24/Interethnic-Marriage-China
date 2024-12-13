## ------------------------------------------------------------------------
##
## Script name: 15.7_loglinear_ethngrp_region.jl
## Purpose: Generate graphs by region
## Author: Yanwen Wang
## Date Created: 2024-11-15
## Email: yanwenwang@u.nus.edu
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

@transform!(
    odds_ratio_df,
    :region = categorical(
        :region,
        levels=["North", "Northeast", "East", "South Central", "Southwest", "Northwest"]
    )
)

# Plot
f = Figure(; size=(1600, 1200), fontsize=12)

odds_ratio_plt = data(odds_ratio_df) * (
    mapping(
        :ethngrp => "",
        :coefficient => "Coefficient (Log Scale)",
        :std_bar,
        dodge_x=:year => "Year",
        color=:year => "Year",
        layout=:region => "Region"
    ) *
    visual(Errorbars) +
    mapping(
        :ethngrp => "",
        :coefficient => "Coefficient (Log Scale)",
        dodge_x=:year => "Year",
        color=:year => "Year",
        layout=:region => "Region"
    ) *
    visual(Scatter)
)

hlines_plt = mapping(0) * visual(HLines, color=(:grey, 0.5), linestyle=:dash)

plt = draw!(
    f[1, 1],
    odds_ratio_plt + hlines_plt,
    scales(
        DodgeX=(; width=0.5),
        Color=(; palette=["#cbd6e4", "#b3bfd1", "#df8879", "#b04238"])
    ),
    axis=(;
        yticks=-12:2:2,
        limits=(nothing, (-12, 1))
    )
)

legend!(f[1, 2], plt)

f

save("graphs/inter_odds_ethngrp_region.png", f; px_per_unit=2)