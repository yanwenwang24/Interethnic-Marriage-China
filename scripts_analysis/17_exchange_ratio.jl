## ------------------------------------------------------------------------
##
## Script name: 17_exchange_ratio.jl
## Purpose: Analyze status exchange using the hypergamy ratio
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

# Create a full combination of ethnic and educational pairings
ethngrp_vector = unique(sample.ethngrp_f)
edu_vector = unique(sample.edu_f)

ethngrp_edu_comb = DataFrame(
    ethngrp_f=[a for a in ethngrp_vector for b in ethngrp_vector for c in edu_vector for d in edu_vector],
    ethngrp_m=[b for a in ethngrp_vector for b in ethngrp_vector for c in edu_vector for d in edu_vector],
    edu_f=[c for a in ethngrp_vector for b in ethngrp_vector for c in edu_vector for d in edu_vector],
    edu_m=[d for a in ethngrp_vector for b in ethngrp_vector for c in edu_vector for d in edu_vector]
)

count_df = @chain sample begin
    @groupby(:ethngrp_m, :ethngrp_f, :edu_f, :edu_m)
    @combine(:n = length(:ethngrp_m))
    # fill missing combinations with 0
    leftjoin(ethngrp_edu_comb, _, on=[:ethngrp_m, :ethngrp_f, :edu_f, :edu_m])
    @transform(:n = coalesce.(:n, 0))
    @orderby(:ethngrp_m, :ethngrp_f, :edu_f, :edu_m)
end

# 2 Parameters -----------------------------------------------------------

count_df = @chain count_df begin
    # Identify minority in interethnic marriage
    @transform(
        :minority = ifelse.(
            :ethngrp_f .!= :ethngrp_m .&& :ethngrp_f .== "Han",
            :ethngrp_m,
            ifelse.(
                :ethngrp_f .!= :ethngrp_m .&& :ethngrp_m .== "Han",
                :ethngrp_f,
                ifelse.(
                    :ethngrp_f .== :ethngrp_m,
                    :ethngrp_f,
                    missing
                )
            )
        )
    )
    # Drop intermarriage among minorities
    @subset(ismissing.(:minority) .== false)
    # Identify which one is minority in intermarriage with Han
    @transform(
        :minority_who = ifelse.(
            :ethngrp_f .!= :ethngrp_m .&& :minority .== :ethngrp_f,
            "female",
            ifelse.(
                :ethngrp_f .!= :ethngrp_m .&& :minority .== :ethngrp_m,
                "male",
                "none"
            )
        )
    )
    # Educational parameters
    @transform(
        :edu = ifelse.(
            :edu_f .== :edu_m,
            "homo",
            ifelse.(
                :edu_f .> :edu_m,
                "hypo",
                "hyper"
            )
        )
    )
    # Drop Kazakh and Uyghur for too few observations
    @subset(:minority .!= "Kazakh", :minority .!= "Uyghur")
end

# 3 Hypergamy ratio ------------------------------------------------------

# 3.1 Observed ratio -----------------------------------------------------

observed_df = @chain count_df begin
    @groupby(:minority, :minority_who, :edu)
    @combine(:total_n = sum(:n))
    unstack(:edu, :total_n)
    @transform(:observed_ratio = :hyper ./ :hypo)
    @select(:minority, :minority_who, :observed_ratio)
end

# 3.2 Structural ratio ---------------------------------------------------

men_df = @chain count_df begin
    @groupby([:minority, :minority_who, :edu_m])
    @combine(:total_men = sum(:n))
end

women_df = @chain count_df begin
    @groupby([:minority, :minority_who, :edu_f])
    @combine(:total_women = sum(:n))
end

structural_df = @chain count_df begin
    @groupby([:minority, :minority_who])
    @combine(:n = sum(:n))
    leftjoin(men_df, on=[:minority, :minority_who])
    leftjoin(women_df, on=[:minority, :minority_who])
    @transform(:expected = (:total_men .* :total_women) ./ :n)
    @transform(:proportion_expected = :expected ./ :n)
    @transform(
        :edu = ifelse.(
            :edu_f .== :edu_m,
            "homo",
            ifelse.(
                :edu_f .> :edu_m,
                "hypo",
                "hyper"
            )
        )
    )
    @groupby([:minority, :minority_who, :edu])
    @combine(:percent = sum(:proportion_expected))
    unstack(:edu, :percent)
    @transform(:structural_ratio = :hyper ./ :hypo)
    @select(:minority, :minority_who, :structural_ratio)
end

# 3.3 Observed-Structural ratio ------------------------------------------

observed_structural_df = leftjoin(observed_df, structural_df, on=[:minority, :minority_who])

observed_structural_df = @chain observed_structural_df begin
    @transform(:observed_structural_ratio = :observed_ratio ./ :structural_ratio)
    @select(:minority, :minority_who, :observed_structural_ratio)
    @orderby(:minority, :minority_who)
end

println(observed_structural_df)