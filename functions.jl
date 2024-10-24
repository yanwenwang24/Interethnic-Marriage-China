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

# Data cleaning -----------------------------------------------------------

#= 
Function to create matches for parents, parents-in-law, or grandparents
within each household with multiple children and children-in-law
=#
function create_parent_matches(sdf)
    pernums = sort(sdf.pernum)
    num_pairs = div(length(pernums), 2)
    hhid = sdf.hhid[1]
    maryr = sdf.maryr[1]
    matches = DataFrame(hhid=String[], pernum=Int[], sploc=Int[])
    for i in 1:num_pairs
        # Pair pernums[2i - 1] with pernums[2i]
        gp1 = pernums[2i-1]
        gp2 = pernums[2i]
        # Assign sploc for both parents
        push!(matches, (hhid=hhid, pernum=gp1, sploc=gp2))
        push!(matches, (hhid=hhid, pernum=gp2, sploc=gp1))
    end
    # If there's an unmatched grandparent (odd number), their 'sploc' remains missing
    return matches
end

#= 
Function to create matches of children and children-in-law
within each household with multiple children and children-in-law
=#
function create_children_matches(sdf)
    # Extract `pernum` of children and children-in-law
    children = sort(sdf[sdf.role.=="child", :pernum])
    children_in_law = sort(sdf[sdf.role.=="child_in_law", :pernum])
    num_pairs = min(length(children), length(children_in_law))
    hhid = sdf.hhid[1]
    maryr = sdf.maryr[1]
    matches = DataFrame(hhid=String[], pernum=Int[], sploc=Int[])
    for i in 1:num_pairs
        child_pernum = children[i]
        child_in_law_pernum = children_in_law[i]
        # Assign sploc for child
        push!(matches, (hhid=hhid, pernum=child_pernum, sploc=child_in_law_pernum))
        # Assign sploc for child-in-law
        push!(matches, (hhid=hhid, pernum=child_in_law_pernum, sploc=child_pernum))
    end
    return matches
end

# Function to calculate normalized entropy with handling for single-category groups
function calculate_entropy(column::AbstractVector)
    counts = countmap(column)  # Count occurrences of each unique element
    total_count = sum(values(counts))  # Total number of elements

    if total_count == 0
        return missing  # Return missing if the group is empty
    end

    probs = [count / total_count for count in values(counts)]  # Calculate probabilities
    k = length(counts)  # Number of unique categories

    # Step 1: Calculate entropy
    H = -sum(p * log2(p) for p in probs if p > 0)  # Shannon entropy formula

    # Step 2: Normalize entropy
    H_max = log2(k)  # Maximum entropy for k categories

    if H_max == 0
        return missing  # Return missing if H_max is zero to avoid division by zero
    end

    H_norm = H / H_max  # Normalized entropy

    return H_norm
end

# Decomposition ----------------------------------------------------------

# Function to decompose differences
function decompose(mat_a, mat_b, outcome = "off")
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
        mod = model_name,
        df = dof_residual(model) - 1,
        deviance = deviance(model),
        id = round(sum(abs.(response(model) - fitted(model))) / (2 * sum(response(model))) * 100, digits=2),
        bic = deviance(model) - (dof_residual(model) - 1) * log(sum(response(model)))
    )
end

# Exchange Index ---------------------------------------------------------

# Function to retrieve relevant sample
function retrieve_sample(i, minority_who = "wif")
    if minority_who == "wif"
        # Restrict samples to Han-Han, minority-minority, and Han-minority marriages
        i_df = @chain sample_EI begin
            @subset(
            (:ethngrp .== :ethngrp_sp .&& :ethngrp .== "Han") .||
            (:ethngrp .== i .&& :ethngrp_sp .== i) .||
            (:ethngrp .== i .&& :ethngrp_sp .== "Han")
        )
        # Identify treatment D (1 = interethnic marriage)
        @transform(:D = ifelse.(:ethngrp .!= :ethngrp_sp, 1, 0))
        end
    elseif minority_who == "hus"
        # Restrict samples to Han-Han, minority-minority, and minority-Han marriages
        i_df = @chain sample_EI begin
            @subset(
            (:ethngrp .== :ethngrp_sp .&& :ethngrp .== "Han") .||
            (:ethngrp .== i .&& :ethngrp_sp .== i) .||
            (:ethngrp .== "Han" .&& :ethngrp_sp .== i)
        )
        # Identify treatment D (1 = interethnic marriage)
        @transform(:D = ifelse.(:ethngrp .!= :ethngrp_sp, 1, 0))
        end
    else error("Invalid minority_who")
    end

    # Treated case
    treat_df = @chain i_df begin
        @subset(:D .== 1)
    end
    
    if minority_who == "wif"
        # Control group from husband's perspective
        control_hus_df = @chain i_df begin
            @subset(:D .== 0, :ethngrp .== "Han")
        end
        # Control group from wife's perspective
        control_wif_df = @chain i_df begin
            @subset(:D .== 0, :ethngrp .== i)
        end
    elseif minority_who == "hus"
        # Control group from husband's perspective
        control_hus_df = @chain i_df begin
            @subset(:D .== 0, :ethngrp .== i)
        end
        # Control group from wife's perspective
        control_wif_df = @chain i_df begin
            @subset(:D .== 0, :ethngrp .== "Han")
        end
    else error("Invalid minority_who")
    end

    # Dataframes for matching from husband's and wife's perspectives
    hus_df = vcat(treat_df, control_hus_df)
    wif_df = vcat(treat_df, control_wif_df)

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
        df[df[!, :D] .== 1, :percentile_sp],
        weights(df[df[!, :D] .== 1, :weights])
    )
    # Husband's educational percentile when D == 0
    hus_intra = mean(
        df[df[!, :D] .== 0, :percentile_sp],
        weights(df[df[!, :D] .== 0, :weights])
    )
    # Wife's educational percentile when D == 1
    wif_inter = mean(
        df[df[!, :D] .== 1, :percentile],
        weights(df[df[!, :D] .== 1, :weights])
    )
    # Wife's educational percentile when D == 0
    wif_intra = mean(
        df[df[!, :D] .== 0, :percentile],
        weights(df[df[!, :D] .== 0, :weights])
    )

    EI_vector = [hus_inter, hus_intra, wif_inter, wif_intra]
    return EI_vector
end

# Functino for extracting p value of the Exchange Index
function extract_p(df)
    # From husband's perspective, comparing wife's educational percentile
    model_hus = lm(@formula(percentile ~ D), df, wts = df[!, :weights])
    p_hus = DataFrame(coeftable(model_hus))[2, 5]

    # From wife's perspective, compariing husband's educational percentile
    model_wif = lm(@formula(percentile_sp ~ D), df, wts = df[!, :weights])
    p_wif = DataFrame(coeftable(model_wif))[2, 5]

    
    p_value = min(p_hus, p_wif)
    return p_value
end
