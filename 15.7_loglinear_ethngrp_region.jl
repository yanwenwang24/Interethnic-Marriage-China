odd_ratio_df = vcat(
    odd_ratio_Huabei,
    odd_ratio_Dongbei,
    odd_ratio_Huadong,
    odd_ratio_Zhongnan,
    odd_ratio_Xinan,
    odd_ratio_Xibei
)

# Plot
f = Figure(; size=(1600, 1200), fontsize=12)

odd_ratio_plt = data(odd_ratio_df) * (
    mapping(
        :ethngrp => "",
        :Coef => "Coefficient (Log Scale)",
        :SE,
        dodge_x=:year => "Year",
        color=:year => "Year",
        layout=:region => "Region"
    ) *
    visual(Errorbars) +
    mapping(
        :ethngrp => "",
        :Coef => "Coefficient (Log Scale)",
        dodge_x=:year => "Year",
        color=:year => "Year",
        layout=:region => "Region"
    ) *
    visual(Scatter)
)

hlines_plt = mapping(0) * visual(HLines, color=(:grey, 0.5), linestyle=:dash)

plt = draw!(
    f[1, 1],
    odd_ratio_plt + hlines_plt,
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