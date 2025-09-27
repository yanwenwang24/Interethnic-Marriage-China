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

# Plot
f = Figure(; size=(1600, 1200), fontsize=12)

odds_ratio_plt = data(odds_ratio_df) * (
    mapping(
        :ethngrp => "",
        :coefficient => "Coefficient (Log Scale)",
        :std_bar,
        dodge_x = :edu => "Education",
        color=:edu => "Education",
        layout=:region => "Region"
    ) *
    visual(Errorbars) +
    mapping(
        :ethngrp => "",
        :coefficient => "Coefficient (Log Scale)",
        dodge_x = :edu => "Education",
        color=:edu => "Education",
        layout=:region => "Region"
    ) *
    visual(Scatter)
)

hlines_plt = mapping(0) * visual(HLines, color=(:grey, 0.5), linestyle=:dash)

plt = draw!(
    f[1, 1],
    odds_ratio_plt + hlines_plt,
    scales(
        DodgeX = (; width = 0.5),
        Color=(; palette=["#d7e1ee", "#bfcbdb", "#a4a2a8", "#c86558", "#991f17"])
    ),
    axis=(;
        yticks=-8:2:2,
        limits=(nothing, (-7, 1))
    )
)

legend!(f[1, 2], plt)

f

save("figures/odds_by_edu_region.png", f; px_per_unit=2)

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