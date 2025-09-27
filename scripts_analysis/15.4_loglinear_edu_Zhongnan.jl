## ------------------------------------------------------------------------
##
## Purpose: Use log-linear models to analyze ethnic and educational mating
## Author: Yanwen Wang
## Date Created: 2024-10-10
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Contingency table -----------------------------------------------------

# Select region Zhongnan
sample_Zhongnan = @chain sample begin
    @subset(:region .== "Zhongnan")
end

# Create a full combination of ethnic and educational pairings
year_vector = unique(sample_Zhongnan.year)
ethngrp_vector = unique(sample_Zhongnan.ethngrp_f)
edu_vector = unique(sample_Zhongnan.edu_f)

ethngrp_edu_comb = DataFrame(
    year=[a for a in year_vector for b in ethngrp_vector for c in ethngrp_vector for d in edu_vector for e in edu_vector],
    ethngrp_f=[b for a in year_vector for b in ethngrp_vector for c in ethngrp_vector for d in edu_vector for e in edu_vector],
    ethngrp_m=[c for a in year_vector for b in ethngrp_vector for c in ethngrp_vector for d in edu_vector for e in edu_vector],
    edu_f=[d for a in year_vector for b in ethngrp_vector for c in ethngrp_vector for d in edu_vector for e in edu_vector],
    edu_m=[e for a in year_vector for b in ethngrp_vector for c in ethngrp_vector for d in edu_vector for e in edu_vector]
)

count_df = @chain sample_Zhongnan begin
    @groupby(:year, :ethngrp_m, :ethngrp_f, :edu_f, :edu_m)
    @combine(:n = length(:ethngrp_m))
    # fill missing combinations with 0
    leftjoin(ethngrp_edu_comb, _, on=[:year, :ethngrp_m, :ethngrp_f, :edu_f, :edu_m])
    @transform(:n = coalesce.(:n, 0))
    @orderby(:year, :ethngrp_m, :ethngrp_f, :edu_f, :edu_m)
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

# 2.3 Education parameters ------------------------------------------------

count_df = @chain count_df begin
    # Homogamy vs. heterogamy
    @transform(:edu_diag = ifelse.(:edu_f .== :edu_m, "homo", "heter"))
    @transform(:edu_diag = categorical(:edu_diag, levels=["heter", "homo"]))

    # Distance of heterogamy
    @transform(
        :edu_diag_aff = ifelse.(
            :edu_f .== :edu_m,
            string.("homo", :edu_f),
            string.("heter", abs.(:edu_m .- :edu_f))
        )
    )
    @transform(:edu_diag_aff = categorical(:edu_diag_aff, levels=["heter1", "homo1", "homo2", "homo3", "heter2"]))
end

count_df = @chain count_df begin
    @transform(
        :n = Int64.(:n),
        :year = categorical(:year),
        :ethngrp_f = categorical(:ethngrp_f, levels=ethngrp_vector),
        :ethngrp_m = categorical(:ethngrp_m, levels=ethngrp_vector),
        :edu_f = categorical(:edu_f),
        :edu_m = categorical(:edu_m)
    )
end

# 3 Log-linear models  -----------------------------------------------------

# 3.1 Model specification --------------------------------------------------

Random.seed!(1024)

M0 = glm(@formula(n ~ ethngrp_f*edu_f*year + ethngrp_m*edu_m*year), count_df, Poisson())

M1 = glm(@formula(n ~ ethngrp_f*edu_f*year + ethngrp_m*edu_m*year + diag_aff), count_df, Poisson())

M2a = glm(@formula(n ~ ethngrp_f*edu_f*year + ethngrp_m*edu_m*year + diag_aff + edu_diag), count_df, Poisson())
M2b = glm(@formula(n ~ ethngrp_f*edu_f*year + ethngrp_m*edu_m*year + diag_aff + edu_diag_aff), count_df, Poisson())

M3a = glm(@formula(n ~ ethngrp_f*edu_f*year + ethngrp_m*edu_m*year + ethngrp_f*ethngrp_m*year + edu_f*edu_m*year + diag_aff*edu_diag_aff), count_df, Poisson())
M3b = glm(@formula(n ~ ethngrp_f*edu_f*year + ethngrp_m*edu_m*year + ethngrp_f*ethngrp_m*year + edu_f*edu_m*year + diag_aff*edu_diag_aff*year), count_df, Poisson())

M4 = glm(@formula(n ~ year*ethngrp_f*ethngrp_m*edu_f*edu_m), count_df, Poisson())

# Store models in a dictionary
model_dict = Dict(
    "M0" => M0,
    "M1" => M1,
    "M2a" => M2a, "M2b" => M2b, 
    "M3a" => M3a, "M3b" => M3b,
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

# Model selected: M3a
odds_ratio_df = calculate_combined_education_coefficients(M3a)
odds_ratio_df[!, :std_bar] = odds_ratio_df[!, :std_error] * 1.96

# Select ethnic groups with significant presence
@chain sample begin
    @subset(:region .== "Zhongnan")
    @groupby(:ethngrp_f)
    @combine(:n = length(:ethngrp_f))
    @subset(:n .> 500)
end

@subset!(odds_ratio_df, :ethngrp .== "Hui" .|| :ethngrp .== "Southern")
odds_ratio_Zhongnan = @transform(odds_ratio_df, :region = "South Central")

# Expotentiate the coefficients
@chain odds_ratio_df begin
    @transform(:ratio = round.(exp.(:coefficient) * 1000, digits=2))
    @transform(
        :coefficient = round.(:coefficient, digits=2),
        :std_error = round.(:std_error, digits=2),
    )
    @select(:ethngrp, :edu, :coefficient, :std_error, :ratio)
    println
end
