## ------------------------------------------------------------------------
##
## Script name: 15.3_loglinear_ethngrp_Huadong.jl
## Purpose: Use log-linear models to analyze interethnic marriage in Huadong
## Author: Yanwen Wang
## Date Created: 2024-11-06
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Contingency table -----------------------------------------------------

# Select region Huadong
sample_Huadong = @chain sample begin
    @subset(:region .== "Huadong")
end

# Create a full combination of ethnic pairings
year_vector = unique(sample_Huadong.year)
ethngrp_vector = unique(sample_Huadong.ethngrp_f)

ethngrp_comb = DataFrame(
    year=[x for x in year_vector for y in ethngrp_vector for z in ethngrp_vector],
    ethngrp_f=[y for x in year_vector for y in ethngrp_vector for z in ethngrp_vector],
    ethngrp_m=[z for x in year_vector for y in ethngrp_vector for z in ethngrp_vector]
)

count_df = @chain sample_Huadong begin
    @groupby(:year, :ethngrp_m, :ethngrp_f)
    @combine(:n = length(:ethngrp_f))
    @orderby(:year, :ethngrp_m, :ethngrp_f)
    # fill missing combinations with 0
    leftjoin(ethngrp_comb, _, on=[:year, :ethngrp_m, :ethngrp_f])
    @transform(:n = coalesce.(:n, 0))
end

# 2 Parameters ------------------------------------------------------------

# 2.1 Levels for categorical variables ------------------------------------

diag_var_levels = [
    "Intra_Han", "Intra_Hui", "Intra_Kazakh", "Intra_Korean",
    "Intra_Manchu", "Intra_Mongolian", "Intra_Southern", "Intra_Tibetan", "Intra_Uyghur",
    "Inter_Han", "Inter_minority"
]

aff_var_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean",
    "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

diag_aff_levels = [
    "Intra_Han", "Intra_Hui", "Intra_Kazakh", "Intra_Korean",
    "Intra_Manchu", "Intra_Mongolian", "Intra_Southern", "Intra_Tibetan", "Intra_Uyghur",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean",
    "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

# 2.2 Main parameters ------------------------------------------------------

count_df = @chain count_df begin
    # On vs. off diagonal (`diag`)
    @transform(:diag = ifelse.(:ethngrp_f .== :ethngrp_m, "Intra", "Inter"))
    @transform(:diag = categorical(:diag, levels=["Intra", "Inter"]))

    # Intermarriage with Han vs. among minorities `aff`
    @transform(
        :aff = ifelse.(
            :ethngrp_f .== :ethngrp_m,
            "Intra",
            ifelse.(
                (:ethngrp_f .!= :ethngrp_m) .&& (:ethngrp_f .== "Han" .|| :ethngrp_m .== "Han"),
                "Inter_Han",
                "Inter_minority"
            )
        )
    )
    @transform(:aff = categorical(:aff, levels=["Intra", "Inter_Han", "Inter_minority"]))

    # Intraethnic marriage by ethnic group (`diag_var`)
    @transform(
        :diag_var = ifelse.(
            :ethngrp_f .== :ethngrp_m,
            string.("Intra_", :ethngrp_f),
            ifelse.(
                (:ethngrp_f .!= :ethngrp_m) .&& (:ethngrp_f .== "Han" .|| :ethngrp_m .== "Han"),
                "Inter_Han",
                "Inter_minority"
            )
        )
    )
    @transform(:diag_var = categorical(:diag_var, levels=diag_var_levels))

    # Intermarriage with Han by ethnic group (`aff_var`)
    @transform(
        :aff_var = ifelse.(
            :ethngrp_f .== :ethngrp_m,
            "Intra",
            ifelse.(
                (:ethngrp_f .!= :ethngrp_m) .&& :ethngrp_f .== "Han",
                string.("Inter_Han", :ethngrp_m),
                ifelse.(
                    (:ethngrp_f .!= :ethngrp_m) .&& :ethngrp_m .== "Han",
                    string.("Inter_Han", :ethngrp_f),
                    "Inter_minority"
                )
            )
        )
    )
    @transform(:aff_var = categorical(:aff_var, levels=aff_var_levels))

    # Intra- and inter-ethnic marriage with Han by ethnic group (`diag_aff`)
    @transform(
        :diag_aff = ifelse.(
            :ethngrp_f .== :ethngrp_m,
            string.("Intra_", :ethngrp_f),
            ifelse.(
                (:ethngrp_f .!= :ethngrp_m) .&& :ethngrp_f .== "Han",
                string.("Inter_Han", :ethngrp_m),
                ifelse.(
                    (:ethngrp_f .!= :ethngrp_m) .&& :ethngrp_m .== "Han",
                    string.("Inter_Han", :ethngrp_f),
                    "Inter_minority"
                )
            )
        )
    )
    @transform(:diag_aff = categorical(:diag_aff, levels=diag_aff_levels))
end

count_df = @chain count_df begin
    @transform(
        :n = Int64.(:n),
        :year = categorical(:year),
        :ethngrp_f = categorical(:ethngrp_f, levels=ethngrp_vector),
        :ethngrp_m = categorical(:ethngrp_m, levels=ethngrp_vector),
    )
end

# 3 Log-linear models  -----------------------------------------------------

# 3.1 Model specification --------------------------------------------------

Random.seed!(1024)

M0 = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m), count_df, Poisson())
M1a = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + diag), count_df, Poisson())
M1b = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff), count_df, Poisson())
M1c = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + diag_var), count_df, Poisson())
M1d = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var), count_df, Poisson())
M1e = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + diag_aff), count_df, Poisson())

M2a = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + diag * year), count_df, Poisson())
M2b = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + aff * year), count_df, Poisson())
M2c = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + diag_var * year), count_df, Poisson())
M2d = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + aff_var * year), count_df, Poisson())
M2e = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + diag_aff * year), count_df, Poisson())

M3 = glm(@formula(n ~ year * ethngrp_f * ethngrp_m), count_df, Poisson())

# Store models in a dictionary
model_dict = Dict(
    "M0" => M0,
    "M1a" => M1a, "M1b" => M1b, "M1c" => M1c, "M1d" => M1d, "M1e" => M1e,
    "M2a" => M2a, "M2b" => M2b, "M2c" => M2c, "M2d" => M2d, "M2e" => M2e,
    "M3" => M3
)

# 3.2 Model comparison -----------------------------------------------------

gof_df = DataFrame(
    # An empty df to store the goodness of fit
    mod=String[],
    df=Float64[],
    deviance=Float64[],
    id=Float64[],
    bic=Float64[]
)

for (name, model) in model_dict
    gof = goodness_of_fit(model, name)
    append!(gof_df, gof)
end

gof_df = @orderby(gof_df, :mod)
println(gof_df)

# 3.3 Odd ratios -----------------------------------------------------------

# Model selected: M2d
odds_ratio_df = calculate_combined_coefficients(M2d)
odds_ratio_df[!, :std_bar] = odds_ratio_df[!, :std_error] * 1.96

# Select ethnic groups with significant presence
@chain sample begin
    @subset(:region .== "Huadong")
    @groupby(:ethngrp_f)
    @combine(:n = length(:ethngrp_f))
    @subset(:n .> 500)
end

@subset!(odds_ratio_df, :ethngrp .== "Hui" .|| :ethngrp .== "Southern")
odds_ratio_Huadong = @transform(odds_ratio_df, :region = "East")

# Plot
f = Figure(; size=(800, 600), fontsize=12)

odds_ratio_plt = data(odds_ratio_df) * (
    mapping(
        :ethngrp => "",
        :coefficient => "Coefficient (Log Scale)",
        :std_bar,
        dodge_x=:year => "Year",
        color=:year => "Year"
    ) *
    visual(Errorbars) +
    mapping(
        :ethngrp => "",
        :coefficient => "Coefficient (Log Scale)",
        dodge_x=:year => "Year",
        color=:year => "Year"
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

save("graphs/inter_odds_ethngrp_Huadong.png", f; px_per_unit=2)

# Expotentiate coefficients
@chain odds_ratio_df begin
    @transform(:ratio = round.(exp.(:coefficient) * 1000, digits=2))
    @transform(
        :coefficient = round.(:coefficient, digits=2),
        :std_error = round.(:std_error, digits=2),
    )
    @select(:ethngrp, :year, :coefficient, :std_error, :ratio)
    println()
end

# 3.4 Gender asymmetry ------------------------------------------------------

pooled_df, temporal_df = analyze_all_minorities(count_df)

temporal_df[!, :year] = categorical(temporal_df[!, :year], levels=year_vector)
temporal_df[!, :std_bar] = temporal_df[!, :std_error] * 1.96

@subset!(pooled_df, :minority_group .== "Hui" .|| :minority_group .== "Southern")
@subset!(temporal_df, :minority_group .== "Hui" .|| :minority_group .== "Southern")

temporal_df_Huadong = @transform(temporal_df, :region = "East")

println(pooled_df)
println(temporal_df)
