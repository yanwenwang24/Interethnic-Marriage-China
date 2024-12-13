## ------------------------------------------------------------------------
##
## Script name: functions.jl
## Purpose: Store functions for data cleaning and analysis
## Author: Yanwen Wang
## Date Created: 2024-10-04
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Decomposition -----------------------------------------------------------

# Function to decompose differences
function decompose(mat_a, mat_b, outcome="off")
    # Create counterfactual matrices
    Z1 = create_new_matrix(mat_a, mat_b)[1]
    Z2 = create_new_matrix(mat_a, mat_b)[2]

    # Real rates
    r1 = calculate_interrates(mat_a, outcome)
    r2 = calculate_interrates(mat_b, outcome)

    # Counterfactual rates
    c1 = calculate_interrates(Z1, outcome)
    c2 = calculate_interrates(Z2, outcome)

    diff_total = r2 - r1
    diff_margin = 1 / 2 * (r2 - c1) + 1 / 2 * (c2 - r1)
    diff_oddratio = 1 / 2 * (c1 - r1) + 1 / 2 * (r2 - c2)

    return [r2, diff_total, diff_margin, diff_oddratio]
end

# Function to calculate proportion on, off, below, or above the diagonal
function calculate_interrates(mat, outcome="off")
    # Convert counts to proportions
    mat_prop = mat / sum(mat)
    if outcome == "on" # Endogamy or homogamy 
        interrates = (sum(mat_prop[i, i] for i in 1:size(mat_prop)[1]))
    elseif outcome == "off" # Exogamy or heterogamy
        interrates = 1 - (sum(mat_prop[i, i] for i in 1:size(mat_prop)[1]))
    elseif outcome == "below" # Hypogamy
        interrates = sum(mat_prop[i, j] for i in 1:size(mat_prop)[1], j in 1:size(mat_prop)[2] if i < j)
    elseif outcome == "above" # Hypergamy
        interrates = sum(mat_prop[i, j] for i in 1:size(mat_prop)[1], j in 1:size(mat_prop)[2] if i > j)
    else
        throw(ArgumentError("Outcome can be on, off, below, or above."))
    end

    return interrates
end

# Function for creating counterfactual matrix using IPF
function create_new_matrix(mat_a, mat_b)

    # Row and column margins, and total for matrix a
    mat_a_row = vec(sum(mat_a, dims=2))
    mat_a_col = vec(sum(mat_a, dims=1))
    mat_a_total = sum(mat_a)

    # Expected counts and odd ratios
    mat_a_expected = [(mat_a_row[i] * mat_a_col[j]) / mat_a_total for i in 1:size(mat_a)[1], j in 1:size(mat_a)[1]]
    mat_a_oddratio = mat_a ./ mat_a_expected

    # Row and column margins, and total for matrix b
    mat_b_row = vec(sum(mat_b, dims=2))
    mat_b_col = vec(sum(mat_b, dims=1))
    mat_b_total = sum(mat_b)

    # Expected counts and odd ratios
    mat_b_expected = [(mat_b_row[i] * mat_b_col[j]) / mat_b_total for i in 1:size(mat_a)[1], j in 1:size(mat_a)[1]]
    mat_b_oddratio = mat_b ./ mat_b_expected

    # Create counterfactual matrix using IPF
    ## First: margins from matrix a, odd ratios from matrix b
    X1 = mat_a_expected .* mat_b_oddratio
    u1 = mat_a_row
    v1 = mat_a_col

    Z1 = Array(ipf(X1, [u1, v1]; maxiter=10000)) .* X1

    ## Second: margins from matrix b, odd ratios from matrix a
    X2 = mat_b_expected .* mat_a_oddratio
    u2 = mat_b_row
    v2 = mat_b_col

    Z2 = Array(ipf(X2, [u2, v2]; maxiter=10000)) .* X2

    return Z1, Z2
end

# Function to get goodness-of-fit statistics
function goodness_of_fit(model, model_name::String)
    return DataFrame(
        mod=model_name,
        df=dof_residual(model) - 1,
        deviance=deviance(model),
        id=round(sum(abs.(response(model) - fitted(model))) / (2 * sum(response(model))) * 100, digits=2),
        bic=deviance(model) - (dof_residual(model) - 1) * log(sum(response(model)))
    )
end

# Exchange Index ---------------------------------------------------------

"""
    equalize_distribution(df, treated_col)

Equalizes the distribution of a specified column between treated and control groups 
through resampling of control cases, following the methodology in Xie and Dong (2021).

Arguments:
- df: DataFrame containing treated and control cases with column D indicating treatment status
- treated_col: Symbol specifying the column whose distribution should be equalized

Returns:
- DataFrame with equalized distributions between treated and control groups
"""
function equalize_distribution(df, treated_col)
    # Split data into treated and control groups
    treated = df[df.D.==1, :]
    control = df[df.D.==0, :]

    # Return original data if either group is empty
    if nrow(treated) == 0 || nrow(control) == 0
        @warn "Either treated or control group is empty. Returning original data."
        return df
    end

    # Calculate group-specific counts and proportions
    treated_props = combine(groupby(treated, treated_col), nrow => :count_treated)
    treated_props.prop_treated = treated_props.count_treated / sum(treated_props.count_treated)

    control_props = combine(groupby(control, treated_col), nrow => :count_control)
    control_props.prop_control = control_props.count_control / sum(control_props.count_control)

    # Join and calculate sampling parameters
    props_df = leftjoin(treated_props, control_props, on=treated_col)
    props_df.sampling_ratio = coalesce.(props_df.count_treated, 0) ./ coalesce.(props_df.count_control, 1)

    # Calculate minimum valid sampling ratio
    valid_ratios = props_df.sampling_ratio[
        .!ismissing.(props_df.sampling_ratio).&(props_df.sampling_ratio.!=Inf).&(props_df.sampling_ratio.>0)
    ]

    if isempty(valid_ratios)
        @warn "No valid sampling ratios found. Returning original data."
        return df
    end

    lambda = minimum(valid_ratios)

    # Calculate target sample sizes
    props_df.target_n = min.(
        coalesce.(props_df.count_control, 0),
        round.(Int, coalesce.(props_df.count_control, 0) .* lambda)
    )

    # Sample control cases
    sampled_control = DataFrame()
    for row in eachrow(props_df)
        level_control = control[control[:, treated_col].==row[treated_col], :]
        if row.target_n > 0
            n_sample = min(row.target_n, nrow(level_control))
            if n_sample > 0
                sampled_indices = StatsBase.sample(1:nrow(level_control), n_sample, replace=false)
                append!(sampled_control, level_control[sampled_indices, :])
            end
        end
    end

    return vcat(treated, sampled_control)
end

"""
    retrieve_sample(i, minority_who="wif"; balance_distribution=false)

Retrieves and processes samples for analyzing interethnic marriages.

Arguments:
- i: String specifying the minority ethnic group
- minority_who: String indicating perspective ("wif" or "hus")
- balance_distribution: Boolean indicating whether to equalize status distributions

Returns:
- Tuple of two DataFrames for analysis from husband's and wife's perspectives
"""
function retrieve_sample(i, minority_who="wif"; balance_distribution=false)
    if minority_who == "wif"
        # Process from wife's minority perspective
        i_df = @chain sample_EI begin
            @subset(
                (:ethngrp .== :ethngrp_sp .&& :ethngrp .== "Han") .||
                (:ethngrp .== i .&& :ethngrp_sp .== i) .||
                (:ethngrp .== i .&& :ethngrp_sp .== "Han")
            )
            @transform(:D = ifelse.(:ethngrp .!= :ethngrp_sp, 1, 0))
        end
    elseif minority_who == "hus"
        # Process from husband's minority perspective
        i_df = @chain sample_EI begin
            @subset(
                (:ethngrp .== :ethngrp_sp .&& :ethngrp .== "Han") .||
                (:ethngrp .== i .&& :ethngrp_sp .== i) .||
                (:ethngrp .== "Han" .&& :ethngrp_sp .== i)
            )
            @transform(:D = ifelse.(:ethngrp .!= :ethngrp_sp, 1, 0))
        end
    else
        error("Invalid minority_who parameter. Must be 'wif' or 'hus'.")
    end

    # Split samples for different perspectives
    treated = @subset(i_df, :D .== 1)

    if minority_who == "wif"
        control_hus = @subset(i_df, :D .== 0, :ethngrp .== "Han")
        control_wif = @subset(i_df, :D .== 0, :ethngrp .== i)
    else
        control_hus = @subset(i_df, :D .== 0, :ethngrp .== i)
        control_wif = @subset(i_df, :D .== 0, :ethngrp .== "Han")
    end

    # Create perspective-specific DataFrames
    hus_df = vcat(treated, control_hus)
    wif_df = vcat(treated, control_wif)

    # Optionally balance distributions
    if balance_distribution
        hus_df = equalize_distribution(hus_df, :percentile)
        wif_df = equalize_distribution(wif_df, :percentile_sp)
    end

    return hus_df, wif_df
end

# Function for performing full exact matching
function matchit(hus_df, wif_df)
    # Perform full exact matching from husband's perspective
    R"match_hus <- matchit(D ~ percentile_sp + birthy_sp, data = $hus_df, method = 'exact')"
    R"matched_hus_df <- match.data(match_hus)"
    @rget matched_hus_df

    # Perform full exact matching from wife's perspective
    R"match_wif <- matchit(D ~ percentile + birthy, data = $wif_df, method = 'exact')"
    R"matched_wif_df <- match.data(match_wif)"
    @rget matched_wif_df

    return matched_hus_df, matched_wif_df
end

# Function for calculating the Exchange Index
function calculate_EI(df)
    # From husband's perspective
    # Husband's educational percentile when D == 1
    hus_inter = mean(
        df[df[!, :D].==1, :percentile_sp],
        weights(df[df[!, :D].==1, :weights])
    )
    # Husband's educational percentile when D == 0
    hus_intra = mean(
        df[df[!, :D].==0, :percentile_sp],
        weights(df[df[!, :D].==0, :weights])
    )
    # Wife's educational percentile when D == 1
    wif_inter = mean(
        df[df[!, :D].==1, :percentile],
        weights(df[df[!, :D].==1, :weights])
    )
    # Wife's educational percentile when D == 0
    wif_intra = mean(
        df[df[!, :D].==0, :percentile],
        weights(df[df[!, :D].==0, :weights])
    )

    EI_vector = [hus_inter, hus_intra, wif_inter, wif_intra]
    return EI_vector
end

# Functino for extracting p value of the Exchange Index
function extract_p(df)
    # From husband's perspective, comparing wife's educational percentile
    model_hus = lm(@formula(percentile ~ D), df, wts=df[!, :weights])
    p_hus = DataFrame(coeftable(model_hus))[2, 5]

    # From wife's perspective, compariing husband's educational percentile
    model_wif = lm(@formula(percentile_sp ~ D), df, wts=df[!, :weights])
    p_wif = DataFrame(coeftable(model_wif))[2, 5]


    p_value = min(p_hus, p_wif)
    return p_value
end

# Get individual ethnicities from ethnic groups
function get_ethnicities_by_group(dict, target_group)
    return [key for (key, value) in dict if value == target_group]
end

# Function to filter DataFrame by ethnic group
function filter_by_ethnic_group(df, dict, target_group)
    target_ethnicities = get_ethnicities_by_group(dict, target_group)
    return filter(row -> row.ethngrp in target_ethnicities, df)
end