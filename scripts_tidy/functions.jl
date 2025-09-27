## ------------------------------------------------------------------------
##
## Script name: functions.jl
## Purpose: Store functions for data cleaning and analysis
## Author: Yanwen Wang
## Date Created: 2024-10-04
## Email: yanwen.wang@nyu.edu
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
