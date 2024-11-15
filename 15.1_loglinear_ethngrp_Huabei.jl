## ------------------------------------------------------------------------
##
## Script name: 15.1_loglinear_ethngrp_Huabei.jl
## Purpose: Use log-linear models to analyze interethnic marriage in Huabei
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

# Select region Huabei
sample_Huabei = @chain sample begin
    @subset(:region .== "Huabei")
end

# Create a full combination of ethnic pairings
year_vector = unique(sample_Huabei.year)
ethngrp_vector = unique(sample_Huabei.ethngrp_f)

ethngrp_comb = DataFrame(
    year=[x for x in year_vector for y in ethngrp_vector for z in ethngrp_vector],
    ethngrp_f=[y for x in year_vector for y in ethngrp_vector for z in ethngrp_vector],
    ethngrp_m=[z for x in year_vector for y in ethngrp_vector for z in ethngrp_vector]
)

count_df = @chain sample_Huabei begin
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

aff_var_Hui_levels = [
    "Intra",
    "Inter_HanHui(hus)", "Inter_HanHui(wif)",
    "Inter_HanKazakh", "Inter_HanKorean",
    "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Kazakh_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh(hus)", "Inter_HanKazakh(wif)",
    "Inter_HanKorean",
    "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Korean_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean(hus)", "Inter_HanKorean(wif)",
    "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Manchu_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean", "Inter_HanManchu(hus)", "Inter_HanManchu(wif)",
    "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Mongolian_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean", "Inter_HanManchu", "Inter_HanMongolian(hus)", "Inter_HanMongolian(wif)",
    "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Southern_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean", "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern(hus)", "Inter_HanSouthern(wif)",
    "Inter_HanTibetan", "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Tibetan_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean", "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan(hus)", "Inter_HanTibetan(wif)",
    "Inter_HanUyghur",
    "Inter_minority"
]

aff_var_Uyghur_levels = [
    "Intra",
    "Inter_HanHui", "Inter_HanKazakh", "Inter_HanKorean", "Inter_HanManchu", "Inter_HanMongolian", "Inter_HanSouthern", "Inter_HanTibetan", "Inter_HanUyghur(hus)", "Inter_HanUyghur(wif)",
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

# 2.3 Gender parameters ----------------------------------------------------

count_df = @chain count_df begin
    # Gender pairing Hui
    @transform(
        :aff_var_Hui = ifelse.(
            :aff_var .== "Inter_HanHui" .&& :ethngrp_f .== "Hui",
            "Inter_HanHui(hus)",
            ifelse.(
                :aff_var .== "Inter_HanHui" .&& :ethngrp_m .== "Hui",
                "Inter_HanHui(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Hui = categorical(String.(:aff_var_Hui), levels=aff_var_Hui_levels))

    # Gender pairing Kazakh
    @transform(
        :aff_var_Kazakh = ifelse.(
            :aff_var .== "Inter_HanKazakh" .&& :ethngrp_f .== "Kazakh",
            "Inter_HanKazakh(hus)",
            ifelse.(
                :aff_var .== "Inter_HanKazakh" .&& :ethngrp_m .== "Kazakh",
                "Inter_HanKazakh(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Kazakh = categorical(String.(:aff_var_Kazakh), levels=aff_var_Kazakh_levels))

    # Gender pairing Korean
    @transform(
        :aff_var_Korean = ifelse.(
            :aff_var .== "Inter_HanKorean" .&& :ethngrp_f .== "Korean",
            "Inter_HanKorean(hus)",
            ifelse.(
                :aff_var .== "Inter_HanKorean" .&& :ethngrp_m .== "Korean",
                "Inter_HanKorean(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Korean = categorical(String.(:aff_var_Korean), levels=aff_var_Korean_levels))

    # Gender pairing Manchu
    @transform(
        :aff_var_Manchu = ifelse.(
            :aff_var .== "Inter_HanManchu" .&& :ethngrp_f .== "Manchu",
            "Inter_HanManchu(hus)",
            ifelse.(
                :aff_var .== "Inter_HanManchu" .&& :ethngrp_m .== "Manchu",
                "Inter_HanManchu(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Manchu = categorical(String.(:aff_var_Manchu), levels=aff_var_Manchu_levels))

    # Gender pairing Mongolian
    @transform(
        :aff_var_Mongolian = ifelse.(
            :aff_var .== "Inter_HanMongolian" .&& :ethngrp_f .== "Mongolian",
            "Inter_HanMongolian(hus)",
            ifelse.(
                :aff_var .== "Inter_HanMongolian" .&& :ethngrp_m .== "Mongolian",
                "Inter_HanMongolian(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Mongolian = categorical(String.(:aff_var_Mongolian), levels=aff_var_Mongolian_levels))

    # Gender pairing Southern
    @transform(
        :aff_var_Southern = ifelse.(
            :aff_var .== "Inter_HanSouthern" .&& :ethngrp_f .== "Southern",
            "Inter_HanSouthern(hus)",
            ifelse.(
                :aff_var .== "Inter_HanSouthern" .&& :ethngrp_m .== "Southern",
                "Inter_HanSouthern(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Southern = categorical(String.(:aff_var_Southern), levels=aff_var_Southern_levels))

    # Gender pairing Tibetan
    @transform(
        :aff_var_Tibetan = ifelse.(
            :aff_var .== "Inter_HanTibetan" .&& :ethngrp_f .== "Tibetan",
            "Inter_HanTibetan(hus)",
            ifelse.(
                :aff_var .== "Inter_HanTibetan" .&& :ethngrp_m .== "Tibetan",
                "Inter_HanTibetan(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Tibetan = categorical(String.(:aff_var_Tibetan), levels=aff_var_Tibetan_levels))

    # Gender pairing Uyghur
    @transform(
        :aff_var_Uyghur = ifelse.(
            :aff_var .== "Inter_HanUyghur" .&& :ethngrp_f .== "Uyghur",
            "Inter_HanUyghur(hus)",
            ifelse.(
                :aff_var .== "Inter_HanUyghur" .&& :ethngrp_m .== "Uyghur",
                "Inter_HanUyghur(wif)",
                :aff_var
            )
        )
    )
    @transform(:aff_var_Uyghur = categorical(String.(:aff_var_Uyghur), levels=aff_var_Uyghur_levels))
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

M2a = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Hui), count_df, Poisson())
M2b = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Kazakh), count_df, Poisson())
M2c = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Korean), count_df, Poisson())
M2d = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Manchu), count_df, Poisson())
M2e = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Mongolian), count_df, Poisson())
M2f = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Southern), count_df, Poisson())
M2g = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Tibetan), count_df, Poisson())
M2h = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + aff_var_Uyghur), count_df, Poisson())

M3a = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + diag * year), count_df, Poisson())
M3b = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + aff * year), count_df, Poisson())
M3c = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + diag_var * year), count_df, Poisson())
M3d = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + aff_var * year), count_df, Poisson())
M3e = glm(@formula(n ~ year * ethngrp_f + year * ethngrp_m + ethngrp_f * ethngrp_m + diag_aff * year), count_df, Poisson())

M4 = glm(@formula(n ~ year * ethngrp_f * ethngrp_m), count_df, Poisson())

# Store models in a dictionary
model_dict = Dict(
    "M0" => M0,
    "M1a" => M1a, "M1b" => M1b, "M1c" => M1c, "M1d" => M1d, "M1e" => M1e,
    "M2a" => M2a, "M2b" => M2b, "M2c" => M2c, "M2d" => M2d, "M2e" => M2e, "M2f" => M2f, "M2g" => M2g, "M2h" => M2h,
    "M3a" => M3a, "M3b" => M3b, "M3c" => M3c, "M3d" => M3d, "M3e" => M3e,
    "M4" => M4
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

# Model selected: M3d
coef_M3d_df = DataFrame(coeftable(M3d))

# Select odd ratios for each ethnic group in 1982 (reference year)
odd_ref = @chain coef_M3d_df begin
    @subset(startswith.(:Name, "aff_var: Inter_Han"))
    @subset(.!occursin.("year", :Name))
    @transform(:Name = replace.(:Name, "aff_var: Inter_Han" => ""))
end

rename!(odd_ref, names(odd_ref)[1:3] .=> [:ethngrp, :Coef, :SE])
@select!(odd_ref, :ethngrp, :Coef, :SE)

# Select interaction terms with years
pattern = r"^aff_var: Inter_Han.* & year.*"

odd_change = @subset(coef_M3d_df, occursin.(pattern, :Name))

# Identify ethnic group and year from selected variables
pattern = r"^aff_var: Inter_Han\s*(?<ethngrp>[\w\s\-]+).* & year\s*:?\s*(?<year>\d+)"

odd_change = @chain odd_change begin
    @transform(:Match = match.(Ref(pattern), :Name))
    @transform(
        :ethngrp = ByRow(m -> m !== nothing ? m["ethngrp"] : missing)(:Match),
        :year = ByRow(m -> m !== nothing ? parse(Int, m["year"]) : missing)(:Match)
    )
    @select(Not(:Match))
end

rename!(odd_change, names(odd_change)[2:3] .=> [:Coef, :SE])
@select!(odd_change, :ethngrp, :year, :Coef, :SE)

odd_ratio_df = leftjoin(odd_change, odd_ref, on=:ethngrp, renamecols="" => "_1982")

# Calculate odd ratios in 1990, 2000, and 2010
odd_ratio_df = @chain odd_ratio_df begin
    @transform(:Coef = :Coef .+ :Coef_1982)
    @transform(:SE = sqrt.(:SE .^ 2 .+ :SE_1982 .^ 2))
    @select(:ethngrp, :year, :Coef, :SE)
end

# Combine with the base year 1982
odd_ref = @transform(odd_ref, :year = 1982)
odd_ratio_df = vcat(odd_ref, odd_ratio_df)
@transform!(odd_ratio_df, :year = categorical(:year))
odd_ratio_df = @orderby(odd_ratio_df, :ethngrp, :year)

# Select ethnic groups with significant presence
@chain sample begin
    @subset(:region .== "Huabei")
    @groupby(:ethngrp_f)
    @combine(:n = length(:ethngrp_f))
    @subset(:n .> 500)
end

@subset!(odd_ratio_df, :ethngrp .== "Hui" .|| :ethngrp .== "Manchu" .|| :ethngrp .== "Mongolian")
odd_ratio_Huabei = @transform(odd_ratio_df, :region = "North")

# Plot
f = Figure(; size=(800, 600), fontsize=12)

odd_ratio_plt = data(odd_ratio_df) * (
    mapping(
        :ethngrp => "",
        :Coef => "Coefficient (Log Scale)",
        :SE,
        dodge_x=:year => "Year",
        color=:year => "Year"
    ) *
    visual(Errorbars) +
    mapping(
        :ethngrp => "",
        :Coef => "Coefficient (Log Scale)",
        dodge_x=:year => "Year",
        color=:year => "Year"
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

save("graphs/inter_odds_ethngrp_Huabei.png", f; px_per_unit=2)

# Expotentiate coefficients
@chain odd_ratio_df begin
    @transform(:ratio = round.(exp.(:Coef) * 1000, digits=2))
    @transform(
        :Coef = round.(:Coef, digits=2),
        :SE = round.(:SE, digits=2),
    )
    @select(:ethngrp, :year, :Coef, :SE, :ratio)
    println()
end