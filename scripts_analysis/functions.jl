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

# Log-linear models ------------------------------------------------------

# Functions for extracting coefficients from log-linear models on ethnicity
function extract_baseline_coefficients(model)
    # Get coefficient table and identify actual column names
    coef_df = DataFrame(coeftable(model))
    coef_colname = names(coef_df)[2]  # Coefficient column
    se_colname = names(coef_df)[3]    # Standard error column

    # Extract baseline coefficients for Han-minority marriages
    baseline_coefficients = @chain coef_df begin
        @subset(startswith.(:Name, "aff_var: Inter_Han"))
        @subset(.!occursin.("year", :Name))
        @transform(:ethngrp = replace.(:Name, "aff_var: Inter_Han" => ""))
        @select(:ethngrp, $coef_colname, $se_colname)
    end

    rename!(baseline_coefficients, [coef_colname, se_colname] .=> ["coefficient", "std_error"])
    return baseline_coefficients
end

function extract_year_interactions(model)
    coef_df = DataFrame(coeftable(model))
    coef_colname = names(coef_df)[2]
    se_colname = names(coef_df)[3]
    pattern = r"^aff_var: Inter_Han\s*(?<ethngrp>[\w\s\-]+).* & year\s*:?\s*(?<year>\d+)"

    # Extract and process year interaction terms
    year_coefficients = @chain coef_df begin
        @subset(occursin.(r"^aff_var: Inter_Han.* & year.*", :Name))
        @transform(:Match = match.(Ref(pattern), :Name))
        @transform(
            :ethngrp = ByRow(m -> m !== nothing ? m["ethngrp"] : missing)(:Match),
            :year = ByRow(m -> m !== nothing ? parse(Int, m["year"]) : missing)(:Match)
        )
        @select(:ethngrp, :year, $coef_colname, $se_colname)
    end

    rename!(year_coefficients, [coef_colname, se_colname] .=> ["coefficient", "std_error"])
    return year_coefficients
end

function calculate_combined_coefficients(model, base_year=1982)
    # Get variance-covariance matrix
    vcov_matrix = vcov(model)
    coef_names = coefnames(model)

    # Extract baseline and year interaction coefficients
    baseline_coef = extract_baseline_coefficients(model)
    year_coef = extract_year_interactions(model)

    # Initialize results DataFrame
    results = DataFrame(
        ethngrp=String[],
        year=Int[],
        coefficient=Float64[],
        std_error=Float64[]
    )

    # Add baseline year results
    for row in eachrow(baseline_coef)
        push!(results, (row.ethngrp, base_year, row.coefficient, row.std_error))
    end

    # Calculate combined coefficients and their standard errors for each year
    for minority in unique(baseline_coef.ethngrp)
        base_idx = findfirst(x -> occursin("aff_var: Inter_Han$minority", x), coef_names)

        if isnothing(base_idx)
            continue
        end

        for year_row in eachrow(filter(r -> r.ethngrp == minority, year_coef))
            year_term = "aff_var: Inter_Han$(minority) & year: $(year_row.year)"
            year_idx = findfirst(x -> x == year_term, coef_names)

            if isnothing(year_idx)
                continue
            end

            # Calculate combined coefficient
            combined_coef = baseline_coef[baseline_coef.ethngrp.==minority, :coefficient][1] +
                            year_row.coefficient

            # Calculate proper standard error using variance-covariance matrix
            combined_var = vcov_matrix[base_idx, base_idx] +
                           vcov_matrix[year_idx, year_idx] +
                           2 * vcov_matrix[base_idx, year_idx]
            combined_se = sqrt(combined_var)

            push!(results, (minority, year_row.year, combined_coef, combined_se))
        end
    end

    # Sort results
    sort!(results, [:ethngrp, :year])
    transform!(results, :year => categorical, renamecols=false)

    return results
end

# Functions for extracting coefficients from log-linear models on ethnicity and eduction
function extract_baseline_ethnic_education(model)
    coef_df = DataFrame(coeftable(model))
    coef_colname = names(coef_df)[2]
    se_colname = names(coef_df)[3]
    
    baseline_coefficients = @chain coef_df begin
        @subset(startswith.(:Name, "diag_aff: Inter_Han"))
        @subset(.!occursin.("edu", :Name))
        @transform(:ethngrp = replace.(:Name, "diag_aff: Inter_Han" => ""))
        @select(:ethngrp, $coef_colname, $se_colname)
    end
    
    rename!(baseline_coefficients, [coef_colname, se_colname] .=> ["coefficient", "std_error"])
    return baseline_coefficients
end

function extract_education_interactions(model)
    coef_df = DataFrame(coeftable(model))
    coef_colname = names(coef_df)[2]
    se_colname = names(coef_df)[3]
    pattern = r"^diag_aff: Inter_Han\s*(?<ethngrp>[\w\s\-]+).* & edu_diag_aff: \s*(?<edu>[\w\s\-]+)"
    
    education_coefficients = @chain coef_df begin
        @subset(occursin.(r"^diag_aff: Inter_Han.* & edu_diag_aff.*", :Name))
        @transform(:Match = match.(Ref(pattern), :Name))
        @transform(
            :ethngrp = ByRow(m -> m !== nothing ? m["ethngrp"] : missing)(:Match),
            :edu = ByRow(m -> m !== nothing ? m["edu"] : missing)(:Match)
        )
        @select(:ethngrp, :edu, $coef_colname, $se_colname)
    end
    
    rename!(education_coefficients, [coef_colname, se_colname] .=> ["coefficient", "std_error"])
    return education_coefficients
end

function calculate_combined_education_coefficients(model)
    vcov_matrix = vcov(model)
    coef_names = coefnames(model)
    edu_levels = ["homo1", "homo2", "homo3", "heter1", "heter2"]
    
    baseline_coef = extract_baseline_ethnic_education(model)
    edu_coef = extract_education_interactions(model)
    
    results = DataFrame(
        ethngrp = String[],
        edu = String[],
        coefficient = Float64[],
        std_error = Float64[]
    )
    
    for row in eachrow(baseline_coef)
        push!(results, (row.ethngrp, "heter1", row.coefficient, row.std_error))
    end
    
    for minority in unique(baseline_coef.ethngrp)
        base_idx = findfirst(x -> occursin("diag_aff: Inter_Han$minority", x), coef_names)
        
        if isnothing(base_idx)
            continue
        end
        
        for edu_row in eachrow(filter(r -> r.ethngrp == minority, edu_coef))
            edu_term = "diag_aff: Inter_Han$(minority) & edu_diag_aff: $(edu_row.edu)"
            edu_idx = findfirst(x -> x == edu_term, coef_names)
            
            if isnothing(edu_idx)
                continue
            end
            
            combined_coef = baseline_coef[baseline_coef.ethngrp .== minority, :coefficient][1] + 
                          edu_row.coefficient
            
            combined_var = vcov_matrix[base_idx, base_idx] + 
                         vcov_matrix[edu_idx, edu_idx] + 
                         2 * vcov_matrix[base_idx, edu_idx]
            combined_se = sqrt(combined_var)
            
            push!(results, (minority, edu_row.edu, combined_coef, combined_se))
        end
    end
    
    sort!(results, [:ethngrp, :edu])
    results.edu = categorical(results.edu, levels=edu_levels)
    
    return results
end

function add_analysis_metrics!(results_df)
    transform!(results_df,
        [:coefficient, :std_error] =>
        ByRow((coef, se) -> (
            odds_ratio = exp(coef),
            ci_lower = exp(coef - 1.96 * se),
            ci_upper = exp(coef + 1.96 * se)
        )) =>
        [:odds_ratio, :ci_lower, :ci_upper]
    )
    return results_df
end

# Functions for testing gender asymmetry in interethnic marriages
function analyze_gender_asymmetry(count_data::DataFrame, minority_group::String)
    analysis_data = @chain count_data begin
        # Create baseline intermarriage indicator
        @transform(
            :base_inter = ifelse.(
                (:ethngrp_f .== minority_group .&& :ethngrp_m .== "Han") .||
                (:ethngrp_f .== "Han" .&& :ethngrp_m .== minority_group),
                1,
                0
            )
        )
        @transform(:base_inter = categorical(:base_inter, levels=[0, 1]))

        # Create gender-specific intermarriage categories
        @transform(
            :gender_inter = ifelse.(
                (:ethngrp_f .== minority_group .&& :ethngrp_m .== "Han"),
                string(minority_group, "(wif)"),
                ifelse.(
                    (:ethngrp_f .== "Han" .&& :ethngrp_m .== minority_group),
                    string(minority_group, "(hus)"),
                    "None"
                )
            )
        )
        @transform(:gender_inter = categorical(
            :gender_inter,
            levels=["None", string(minority_group, "(hus)"), string(minority_group, "(wif)")]
        ))
    end

    # Fit models
    baseline_model = glm(
        @formula(n ~ year * ethngrp_f + year * ethngrp_m + base_inter),
        analysis_data,
        Poisson()
    )

    gender_model = glm(
        @formula(n ~ year * ethngrp_f + year * ethngrp_m + gender_inter),
        analysis_data,
        Poisson()
    )

    # Likelihood ratio test
    ll_difference = loglikelihood(gender_model) - loglikelihood(baseline_model)
    lr_statistic = 2 * ll_difference
    lr_p_value = 1 - cdf(Chisq(1), lr_statistic)

    # Extract coefficients
    coef_names = coefnames(gender_model)
    hus_index = findfirst(x -> occursin(string(minority_group, "(hus)"), String(x)), coef_names)
    wif_index = findfirst(x -> occursin(string(minority_group, "(wif)"), String(x)), coef_names)

    if isnothing(hus_index) || isnothing(wif_index)
        error("Could not find gender-specific coefficients for $minority_group")
    end

    # Calculate statistics
    coefficient = coef(gender_model)[hus_index] - coef(gender_model)[wif_index]
    pooled_se = sqrt(vcov(gender_model)[hus_index, hus_index] +
                     vcov(gender_model)[wif_index, wif_index] -
                     2 * vcov(gender_model)[hus_index, wif_index])

    z_statistic = coefficient / pooled_se
    wald_p_value = 2 * (1 - cdf(Normal(), abs(z_statistic)))
    odds_ratio = exp(coefficient)

    return Dict(
        "minority_group" => minority_group,
        "coefficient" => coefficient,
        "std_error" => pooled_se,
        "z_statistic" => z_statistic,
        "wald_p_value" => wald_p_value,
        "odds_ratio" => odds_ratio,
        "lr_statistic" => lr_statistic,
        "lr_p_value" => lr_p_value
    )
end

function analyze_all_minorities(count_data::DataFrame)
    minority_groups = ethngrp_vector[ethngrp_vector.!="Han"]

    # Initialize results with named columns
    results = DataFrame(
        minority_group=String[],
        coefficient=Float64[],
        std_error=Float64[],
        z_statistic=Float64[],
        wald_p_value=Float64[],
        odds_ratio=Float64[],
        lr_statistic=Float64[],
        lr_p_value=Float64[]
    )

    for minority in minority_groups
        try
            analysis = analyze_gender_asymmetry(count_data, minority)

            # Create a named tuple for insertion
            row = (
                minority_group=analysis["minority_group"],
                coefficient=analysis["coefficient"],
                std_error=analysis["std_error"],
                z_statistic=analysis["z_statistic"],
                wald_p_value=analysis["wald_p_value"],
                odds_ratio=analysis["odds_ratio"],
                lr_statistic=analysis["lr_statistic"],
                lr_p_value=analysis["lr_p_value"]
            )

            push!(results, row)

        catch e
            println("Error analyzing $minority: ", e)
        end
    end

    # Sort results by minority group
    sort!(results, :minority_group)

    return results
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