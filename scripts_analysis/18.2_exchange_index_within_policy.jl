## ------------------------------------------------------------------------
##
## Purpose: Analyze status exchange in provinces WITH preferential birth policy
## Author: Yanwen Wang
## Date Created: 2025-10-27
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes: Xie, Y., & Dong, H. (2021).
## A New Methodological Framework for Studying Status Exchange in Marriage.
## American Journal of Sociology, 126(5), 1179–1219.
## https://doi.org/10.1086/713927
##
## This script analyzes provinces WITH preferential birth policies for
## majority-minority couples.
##
## ------------------------------------------------------------------------

# 0 Policy information and sample selection ----------------------------------

# Create policy dictionary (0 = no policy, 1 = has policy)
hm_policy_dict = Dict(
    "11" => 0,  # Beijing
    "12" => 0,  # Tianjin
    "13" => 0,  # Hebei
    "14" => 0,  # Shanxi
    "15" => 1,  # Inner Mongolia
    "21" => 1,  # Liaoning
    "22" => 0,  # Jilin
    "23" => 0,  # Heilongjiang
    "31" => 0,  # Shanghai
    "32" => 0,  # Jiangsu
    "33" => 1,  # Zhejiang
    "34" => 0,  # Anhui
    "35" => 1,  # Fujian
    "36" => 0,  # Jiangxi
    "37" => 0,  # Shandong
    "41" => 0,  # Henan
    "42" => 0,  # Hubei
    "43" => 1,  # Hunan
    "44" => 1,  # Guangdong
    "45" => 0,  # Guangxi
    "46" => 1,  # Hainan
    "50" => 1,  # Chongqing
    "51" => 1,  # Sichuan
    "52" => 1,  # Guizhou
    "53" => 1,  # Yunnan
    "54" => 1,  # Tibet
    "61" => 0,  # Shaanxi
    "62" => 1,  # Gansu
    "63" => 1,  # Qinghai
    "64" => 1,  # Ningxia
    "65" => 1   # Xinjiang
)

# Create subsample for provinces WITH policy (assumes hm_policy already joined in previous script)
sample_with_policy = @chain sample begin
    @subset(:hm_policy .== 1)
end

# 1 Education Ranks -------------------------------------------------------

# 1.1 Reference sample ----------------------------------------------------

ref_women = @chain census begin
    @subset(:hm_policy .== 1)
    @subset(:female .== 1)
    @subset(ismissing.(:eduraw) .== false)
    @subset(ismissing.(:age) .== false)
    @select(:birthy, :eduraw)
end

ref_men = @chain census begin
    @subset(:hm_policy .== 1)
    @subset(:female .== 0)
    @subset(ismissing.(:eduraw) .== false)
    @subset(ismissing.(:age) .== false)
    @select(:birthy, :eduraw)
end

# 1.2 Women's education ranks ----------------------------------------------

birthy_vector = sort(unique(sample_with_policy[!, :birthy]))

# Create an empty DataFrame
edu_rank_df = DataFrame(birthy = Int[], eduraw = Int[], percentile = Float64[])

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

birthy_vector = sort(unique(sample_with_policy[!, :birthy_sp]))

# Create an empty DataFrame
edu_rank_df = DataFrame(birthy = Int[], eduraw = Int[], percentile = Float64[])

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
sample_EI = @chain sample_with_policy begin
    @select(
        :year, :birthy, :birthy_sp,
        :ethngrp, :ethngrp_sp, :ethngrp_f, :ethngrp_m,
        :eduraw, :eduraw_sp, :eduraw_f, :eduraw_m
    )
    leftjoin(edu_rank_df_women, on = [:birthy, :eduraw])
    leftjoin(edu_rank_df_men, on = [:birthy_sp, :eduraw_sp])
end

# 2 Matching --------------------------------------------------------------

ethngrp_vector = ["Hui", "Korean", "Manchu", "Mongolian", "Southern", "Tibetan"]

# 2.1 Han husband minority wife -------------------------------------------

EI_df = DataFrame(
    hus_inter = Float64[],
    hus_intra = Float64[],
    wif_inter = Float64[],
    wif_intra = Float64[],
    p_value = Float64[],
    ethngrp = String[],
    who = String[]
)

for i in ethngrp_vector
    # Retrieve sample
    hus_df, wif_df = retrieve_sample(i, "wif", balance_distribution=false)
    # Match samples
    matched_hus_df, matched_wif_df = matchit(hus_df, wif_df)
    # Calculate EI
    EI_hus = calculate_EI(matched_hus_df)
    EI_wif = calculate_EI(matched_wif_df)
    # Append p-value
    v1 = vcat(EI_hus, extract_p(matched_hus_df))
    v2 = vcat(EI_wif, extract_p(matched_wif_df))

    EI_df_i = DataFrame(vcat(v1', v2'), :auto)
    @transform!(EI_df_i, :ethngrp = i, :who = ["hus", "wif"])
    rename!(EI_df_i, names(EI_df_i)[1:5] .=> ["hus_inter", "hus_intra", "wif_inter", "wif_intra", "p_value"])

    append!(EI_df, EI_df_i)
end

EI_df_Hanhus = @transform(EI_df, :ethngrp_pair = string.("Han-", :ethngrp))

# 2.2 Minority husband Han wife -------------------------------------------

EI_df = DataFrame(
    hus_inter = Float64[],
    hus_intra = Float64[],
    wif_inter = Float64[],
    wif_intra = Float64[],
    p_value = Float64[],
    ethngrp = String[],
    who = String[]
)

for i in ethngrp_vector
    # Retrieve sample
    hus_df, wif_df = retrieve_sample(i, "hus", balance_distribution=false)
    # Match samples
    matched_hus_df, matched_wif_df = matchit(hus_df, wif_df)
    # Calculate EI
    EI_hus = calculate_EI(matched_hus_df)
    EI_wif = calculate_EI(matched_wif_df)
    # Append p-value
    v1 = vcat(EI_hus, extract_p(matched_hus_df))
    v2 = vcat(EI_wif, extract_p(matched_wif_df))

    EI_df_i = DataFrame(vcat(v1', v2'), :auto)
    @transform!(EI_df_i, :ethngrp = i, :who = ["hus", "wif"])
    rename!(EI_df_i, names(EI_df_i)[1:5] .=> ["hus_inter", "hus_intra", "wif_inter", "wif_intra", "p_value"])

    append!(EI_df, EI_df_i)
end

EI_df_Hanwif = @transform(EI_df, :ethngrp_pair = string.(:ethngrp, "-Han"))

EI_df = vcat(EI_df_Hanhus, EI_df_Hanwif)

# 3 Output ---------------------------------------------------------------

EI_df = @chain EI_df begin
    @transform(
        :EI = ifelse.(
            :who .== "hus",
            :wif_inter .- :wif_intra,
            :hus_inter .- :hus_intra)
    )
    @transform(:EI = round.(:EI, digits = 2))
    @select(:ethngrp, :ethngrp_pair, :who, :hus_inter, :hus_intra, :wif_inter, :wif_intra, :EI, :p_value)
    @orderby(:ethngrp, :ethngrp_pair, :who)
end

EI_df_short = @chain EI_df begin
    @select(:ethngrp, :ethngrp_pair, :who, :EI, :p_value)
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
    @select(:ethngrp_pair, :who, :EI)
    unstack(:who, :EI)
end

println(EI_df)
println(EI_df_short)
