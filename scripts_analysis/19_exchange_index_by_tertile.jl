## ------------------------------------------------------------------------
##
## Purpose: Analyze status exchange by education tertile
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes: Xie, Y., & Dong, H. (2021).
## A New Methodological Framework for Studying Status Exchange in Marriage.
## American Journal of Sociology, 126(5), 1179–1219.
## https://doi.org/10.1086/713927
##
## Tests whether the reversed EI for Tibetan and Southern minorities
## holds across the educational distribution.
##
## ------------------------------------------------------------------------

# 1 Education Ranks -------------------------------------------------------

# 1.1 Reference sample ----------------------------------------------------

ref_women = @chain census begin
    @subset(:female .== 1)
    @subset(ismissing.(:eduraw) .== false)
    @subset(ismissing.(:age) .== false)
    @select(:birthy, :eduraw)
end

ref_men = @chain census begin
    @subset(:female .== 0)
    @subset(ismissing.(:eduraw) .== false)
    @subset(ismissing.(:age) .== false)
    @select(:birthy, :eduraw)
end

# 1.2 Women's education ranks ----------------------------------------------

birthy_vector = sort(unique(sample[!, :birthy]))

# Create an empty DataFrame
edu_rank_df = DataFrame(birthy=Int[], eduraw=Int[], percentile=Float64[])

# Identify educational rankings by gender and 11-year moving cohorts
for i in birthy_vector
    # Select samples within 11-year moving cohorts
    df = @subset(ref_women, :birthy .>= i - 5 .&& :birthy .<= i + 5)

    # Calculate education rankings and percentiles
    df[!, :edu_rank] = tiedrank(df[!, :eduraw])
    @transform!(df, :percentile = :edu_rank / nrow(df) * 100)
    @transform!(df, :birthy = i)
    @select!(df, :birthy, :eduraw, :percentile)
    df = sort(unique(df[!, :]))

    # Append to the DataFrame
    append!(edu_rank_df, df)
end

edu_rank_df_women = edu_rank_df

# 1.3 Men's education ranks -----------------------------------------------

birthy_vector = sort(unique(sample[!, :birthy_sp]))

# Create an empty DataFrame
edu_rank_df = DataFrame(birthy=Int[], eduraw=Int[], percentile=Float64[])

# Identify educational rankings by gender and 11-year moving cohorts
for i in birthy_vector
    # Select samples within 11-year moving cohorts
    df = @subset(ref_men, :birthy .>= i - 5 .&& :birthy .<= i + 5)

    # Calculate education rankings and percentiles
    df[!, :edu_rank] = tiedrank(df[!, :eduraw])
    @transform!(df, :percentile = :edu_rank / nrow(df) * 100)
    @transform!(df, :birthy = i)
    @select!(df, :birthy, :eduraw, :percentile)
    df = sort(unique(df[!, :]))

    # Append to the DataFrame
    append!(edu_rank_df, df)
end

edu_rank_df_men = edu_rank_df
edu_rank_df_men = @chain edu_rank_df_men begin
    @rename(
        :birthy_sp = :birthy,
        :eduraw_sp = :eduraw,
        :percentile_sp = :percentile
    )
end

# Join to the sample
sample_EI = @chain sample begin
    @select(
        :year, :birthy, :birthy_sp,
        :ethngrp, :ethngrp_sp, :ethngrp_f, :ethngrp_m,
        :eduraw, :eduraw_sp, :eduraw_f, :eduraw_m
    )
    leftjoin(edu_rank_df_women, on=[:birthy, :eduraw])
    leftjoin(edu_rank_df_men, on=[:birthy_sp, :eduraw_sp])
end

# 2 Helper functions -------------------------------------------------------

"""
    assign_tertile_group(df, col)

Assigns each row to a tertile group (1, 2, 3) based on the distribution of `col`.
Returns a copy of the DataFrame with a new `:tertile_group` column.
"""
function assign_tertile_group(df::DataFrame, col::Symbol)
    result = copy(df)
    vals = result[!, col]
    q33 = quantile(vals, 1 / 3)
    q67 = quantile(vals, 2 / 3)
    result[!, :tertile_group] = ifelse.(
        vals .<= q33, 1,
        ifelse.(vals .<= q67, 2, 3)
    )
    return result
end

"""
    calculate_EI_by_tertile(matched_df, stratify_col)

Stratifies the matched DataFrame by tertiles of `stratify_col` and computes
the Exchange Index within each tertile.
Returns a DataFrame with columns: hus_inter, hus_intra, wif_inter, wif_intra, p_value, tertile.
"""
function calculate_EI_by_tertile(matched_df::DataFrame, stratify_col::Symbol)
    df = assign_tertile_group(matched_df, stratify_col)

    results = DataFrame(
        hus_inter=Float64[],
        hus_intra=Float64[],
        wif_inter=Float64[],
        wif_intra=Float64[],
        p_value=Float64[],
        tertile=Int[]
    )

    for t in [1, 2, 3]
        subset_t = df[df.tertile_group.==t, :]
        n_treated = sum(subset_t.D .== 1)
        n_control = sum(subset_t.D .== 0)

        if n_treated == 0 || n_control == 0
            @warn "Tertile $t: empty treated ($n_treated) or control ($n_control) group. Skipping."
            continue
        end

        EI_vals = calculate_EI(subset_t)
        p_val = extract_p(subset_t)
        push!(results, (EI_vals[1], EI_vals[2], EI_vals[3], EI_vals[4], p_val, t))
    end

    return results
end

"""
    fit_interaction_model(matched_df, outcome_col, stratify_col)

Fits a weighted OLS model with D * tertile_cat interaction on the matched data.
Returns a NamedTuple with interaction coefficients, their p-values, and an F-test p-value.
"""
function fit_interaction_model(matched_df::DataFrame, outcome_col::Symbol, stratify_col::Symbol)
    df = assign_tertile_group(matched_df, stratify_col)
    df[!, :tertile_cat] = categorical(df[!, :tertile_group], levels=[1, 2, 3])

    # Fit full and restricted models (branch on outcome_col since @formula
    # does not support interpolation)
    if outcome_col == :percentile
        full_model = lm(
            @formula(percentile ~ D * tertile_cat), df, wts=df[!, :weights]
        )
        restricted_model = lm(
            @formula(percentile ~ D + tertile_cat), df, wts=df[!, :weights]
        )
    elseif outcome_col == :percentile_sp
        full_model = lm(
            @formula(percentile_sp ~ D * tertile_cat), df, wts=df[!, :weights]
        )
        restricted_model = lm(
            @formula(percentile_sp ~ D + tertile_cat), df, wts=df[!, :weights]
        )
    else
        error("outcome_col must be :percentile or :percentile_sp")
    end

    # Extract interaction coefficients and p-values from the full model
    ct = DataFrame(coeftable(full_model))
    coef_colname = names(ct)[2]
    p_colname = names(ct)[5]

    # Interaction rows: D & tertile_cat: 2 and D & tertile_cat: 3
    interaction_rows = ct[occursin.("D & tertile_cat", ct.Name), :]

    coef_D_t2 = interaction_rows[1, coef_colname]
    coef_D_t3 = interaction_rows[2, coef_colname]
    p_D_t2 = interaction_rows[1, p_colname]
    p_D_t3 = interaction_rows[2, p_colname]

    # F-test for joint significance of interaction terms
    # GLM's ftest fails with weighted models (nobs is sum of weights, not integer),
    # so compute the F-statistic manually from weighted residual sum of squares
    rss_full = deviance(full_model)
    rss_restricted = deviance(restricted_model)
    p_full = length(coef(full_model))
    p_restricted = length(coef(restricted_model))
    n = nrow(df)
    df_num = p_full - p_restricted      # numerator df (= 2 interaction terms)
    df_den = n - p_full                  # denominator df
    f_stat = ((rss_restricted - rss_full) / df_num) / (rss_full / df_den)
    f_test_p = 1 - cdf(FDist(df_num, df_den), f_stat)

    return (
        coef_D_t2=coef_D_t2,
        coef_D_t3=coef_D_t3,
        p_D_t2=p_D_t2,
        p_D_t3=p_D_t3,
        f_test_p=f_test_p
    )
end

# 3 Analysis — Han husband, minority wife -----------------------------------

ethngrp_vector = ["Hui", "Korean", "Manchu", "Mongolian", "Southern", "Tibetan"]

# Initialize result DataFrames
EI_tertile_df = DataFrame(
    ethngrp=String[],
    who=String[],
    tertile=Int[],
    hus_inter=Float64[],
    hus_intra=Float64[],
    wif_inter=Float64[],
    wif_intra=Float64[],
    p_value=Float64[]
)

interaction_df = DataFrame(
    ethngrp=String[],
    who=String[],
    coef_D_t2=Float64[],
    coef_D_t3=Float64[],
    p_D_t2=Float64[],
    p_D_t3=Float64[],
    f_test_p=Float64[]
)

for i in ethngrp_vector
    # Shared matching
    hus_df, wif_df = retrieve_sample(i, "wif", balance_distribution=false)
    matched_hus_df, matched_wif_df = matchit(hus_df, wif_df)

    # --- Analysis A: Stratified EI ---
    # Husband perspective: stratify by percentile_sp (husband's education)
    EI_by_t_hus = calculate_EI_by_tertile(matched_hus_df, :percentile_sp)
    for row in eachrow(EI_by_t_hus)
        push!(EI_tertile_df, (i, "hus", row.tertile,
            row.hus_inter, row.hus_intra, row.wif_inter, row.wif_intra, row.p_value))
    end

    # Wife perspective: stratify by percentile (wife's education)
    EI_by_t_wif = calculate_EI_by_tertile(matched_wif_df, :percentile)
    for row in eachrow(EI_by_t_wif)
        push!(EI_tertile_df, (i, "wif", row.tertile,
            row.hus_inter, row.hus_intra, row.wif_inter, row.wif_intra, row.p_value))
    end

    # --- Analysis B: Interaction model ---
    # Husband perspective: outcome = wife's percentile, stratify by husband's
    int_hus = fit_interaction_model(matched_hus_df, :percentile, :percentile_sp)
    push!(interaction_df, (i, "hus", int_hus...))

    # Wife perspective: outcome = husband's percentile, stratify by wife's
    int_wif = fit_interaction_model(matched_wif_df, :percentile_sp, :percentile)
    push!(interaction_df, (i, "wif", int_wif...))
end

EI_tertile_Hanhus = @transform(EI_tertile_df, :ethngrp_pair = string.("Han-", :ethngrp))
interaction_Hanhus = @transform(interaction_df, :ethngrp_pair = string.("Han-", :ethngrp))

# 4 Analysis — Minority husband, Han wife -----------------------------------

EI_tertile_df = DataFrame(
    ethngrp=String[],
    who=String[],
    tertile=Int[],
    hus_inter=Float64[],
    hus_intra=Float64[],
    wif_inter=Float64[],
    wif_intra=Float64[],
    p_value=Float64[]
)

interaction_df = DataFrame(
    ethngrp=String[],
    who=String[],
    coef_D_t2=Float64[],
    coef_D_t3=Float64[],
    p_D_t2=Float64[],
    p_D_t3=Float64[],
    f_test_p=Float64[]
)

for i in ethngrp_vector
    # Shared matching
    hus_df, wif_df = retrieve_sample(i, "hus", balance_distribution=false)
    matched_hus_df, matched_wif_df = matchit(hus_df, wif_df)

    # --- Analysis A: Stratified EI ---
    EI_by_t_hus = calculate_EI_by_tertile(matched_hus_df, :percentile_sp)
    for row in eachrow(EI_by_t_hus)
        push!(EI_tertile_df, (i, "hus", row.tertile,
            row.hus_inter, row.hus_intra, row.wif_inter, row.wif_intra, row.p_value))
    end

    EI_by_t_wif = calculate_EI_by_tertile(matched_wif_df, :percentile)
    for row in eachrow(EI_by_t_wif)
        push!(EI_tertile_df, (i, "wif", row.tertile,
            row.hus_inter, row.hus_intra, row.wif_inter, row.wif_intra, row.p_value))
    end

    # --- Analysis B: Interaction model ---
    int_hus = fit_interaction_model(matched_hus_df, :percentile, :percentile_sp)
    push!(interaction_df, (i, "hus", int_hus...))

    int_wif = fit_interaction_model(matched_wif_df, :percentile_sp, :percentile)
    push!(interaction_df, (i, "wif", int_wif...))
end

EI_tertile_Hanwif = @transform(EI_tertile_df, :ethngrp_pair = string.(:ethngrp, "-Han"))
interaction_Hanwif = @transform(interaction_df, :ethngrp_pair = string.(:ethngrp, "-Han"))

# Combine both directions
EI_tertile_df = vcat(EI_tertile_Hanhus, EI_tertile_Hanwif)
interaction_df = vcat(interaction_Hanhus, interaction_Hanwif)

# 5 Output — Analysis A (stratified EI) ------------------------------------

EI_tertile_df = @chain EI_tertile_df begin
    @transform(
        :EI = ifelse.(
            :who .== "hus",
            :wif_inter .- :wif_intra,
            :hus_inter .- :hus_intra)
    )
    @transform(:EI = round.(:EI, digits=2))
    @select(:ethngrp, :ethngrp_pair, :who, :tertile, :EI, :p_value)
    @orderby(:ethngrp, :ethngrp_pair, :who, :tertile)
end

println("=== Analysis A: Exchange Index by Education Tertile ===")
println(EI_tertile_df)

EI_tertile_short = @chain EI_tertile_df begin
    @transform(
        :sign = ifelse.(
            :p_value .< 0.001,
            "***",
            ifelse.(
                :p_value .< 0.01,
                "**",
                ifelse.(
                    :p_value .< 0.05,
                    "*",
                    ""
                )
            )
        )
    )
    @transform(:EI = string.(:EI, :sign))
    @transform(:label = string.(:who, "_T", :tertile))
    @select(:ethngrp_pair, :label, :EI)
    unstack(:label, :EI)
end

println(EI_tertile_short)

# 6 Output — Analysis B (interaction model) ---------------------------------

interaction_df = @chain interaction_df begin
    @transform(
        :coef_D_t2 = round.(:coef_D_t2, digits=2),
        :coef_D_t3 = round.(:coef_D_t3, digits=2)
    )
    @orderby(:ethngrp, :ethngrp_pair, :who)
end

println("=== Analysis B: Interaction Model (D × Tertile) ===")
println(interaction_df)
