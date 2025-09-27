## ------------------------------------------------------------------------
##
## Script name: 14_decompose_ethngrp.jl
## Purpose: Decompose ethnic sorting outcomes using IPF
## Author: Yanwen Wang
## Date Created: 2024-10-07
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes: Decompose changes in interethnic marriage rates
## by ethnic composition and odd ratios
## using Iterative Proportional Fitting (IPF).
##
## ------------------------------------------------------------------------

# 1 Decomposition ---------------------------------------------------------

# Matrix A (1982 as the reference year)
df_a = @subset(sample, :year .== 1982)
mat_a = Matrix(freqtable(df_a, :ethngrp_f, :ethngrp_m)) .+ 1e-6

decompose_tuple = Vector{Tuple{Float64,Float64,Float64,Float64}}()

# Decompose difference in intermarriage rates across years
for year in [1982, 1990, 2000, 2010]
    df_b = @subset(sample, :year .== year)
    mat_b = Matrix(freqtable(df_b, :ethngrp_f, :ethngrp_m)) .+ 1e-6

    push!(decompose_tuple, Tuple(decompose(mat_a, mat_b, "off")))
end

colnames = [:inter_ethngrp, :diff_total, :diff_margin, :diff_oddratio]
decompose_df = DataFrame(decompose_tuple, colnames)
decompose_df = @chain decompose_df begin
    @transform(:year = [1982, 1990, 2000, 2010])
    @rename(:structure = :diff_margin, :preference = :diff_oddratio)
    @select(:year, :inter_ethngrp, :structure, :preference)
end

# Plot
f = Figure(; size=(800, 600), fontsize=12)

decompose_df_for_plot = stack(@select(decompose_df, :year, :structure, :preference), Not(:year))

decompose_plt = data(decompose_df_for_plot) *
                mapping(
                    :year => "Year",
                    :value => "Difference",
                    color=:variable => "Source of change",
                    stack=:variable
                ) *
                visual(BarPlot)

plt = draw!(
    f[1, 1],
    decompose_plt,
    scales(Color=(; palette=["#d7e1ee", "#991f17"])),
)

legend!(f[1, 2], plt)
f

save("graphs/decompose.png", f; px_per_unit=2)