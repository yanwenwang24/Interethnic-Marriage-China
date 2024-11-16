## ------------------------------------------------------------------------
##
## Script name: 16.7_loglinear_edu_region.jl
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

odd_ratio_df = vcat(
    odd_ratio_Huabei,
    odd_ratio_Dongbei,
    odd_ratio_Huadong,
    odd_ratio_Zhongnan,
    odd_ratio_Xinan,
    odd_ratio_Xibei
)

@transform!(odd_ratio_df, :region = categorical(:region, levels=["North", "Northeast", "East", "South Central", "Southwest", "Northwest"]))

# Plot
f = Figure(; size=(1600, 1200), fontsize=12)

odd_ratio_plt = data(odd_ratio_df) * (
    mapping(
        :ethngrp => "",
        :Coef => "Coefficient (Log Scale)",
        :SE,
        dodge_x = :edu => "Education",
        color=:edu => "Education",
        layout=:region => "Region"
    ) *
    visual(Errorbars) +
    mapping(
        :ethngrp => "",
        :Coef => "Coefficient (Log Scale)",
        dodge_x = :edu => "Education",
        color=:edu => "Education",
        layout=:region => "Region"
    ) *
    visual(Scatter)
)

hlines_plt = mapping(0) * visual(HLines, color=(:grey, 0.5), linestyle=:dash)

plt = draw!(
    f[1, 1],
    odd_ratio_plt + hlines_plt,
    scales(
        DodgeX = (; width = 0.5),
        Color=(; palette=["#d7e1ee", "#bfcbdb", "#a4a2a8", "#c86558", "#991f17"])
    ),
    axis=(;
        yticks=-10:2:2,
        limits=(nothing, (-9, 1))
    )
)

legend!(f[1, 2], plt)

f

save("graphs/inter_odds_edu_region.png", f; px_per_unit=2)

# Expotentiate the coefficients
@chain odd_ratio_df begin
    @transform(:ratio = round.(exp.(:Coef) * 1000, digits=2))
    @transform(
        :Coef = round.(:Coef, digits=2),
        :SE = round.(:SE, digits=2),
    )
    @select(:region, :ethngrp, :edu, :Coef, :SE, :ratio)
    @subset(:ethngrp .== "Manchu")
    println
end