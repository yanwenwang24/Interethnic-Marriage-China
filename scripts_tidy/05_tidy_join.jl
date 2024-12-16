## ------------------------------------------------------------------------
##
## Script name: 05_tidy_join.jl
## Purpose: Combine cleaned data and construct the final dataset
## Author: Yanwen Wang
## Date Created: 2024-10-05
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Combine cleaned data --------------------------------------------------

# Combine cleaned data
census = vcat(census_1982, census_1990, census_2000, census_2010)

@transform!(census, :birthy_sp = :year - :age_sp)

# 2 Construct variables ---------------------------------------------------

# 2.1 Ethnic pairing ------------------------------------------------------

# Interethnic marriage by ethnicity
inter_ethnic = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.ethnicity_m[i]
    f = census.ethnicity_f[i]

    if ismissing(m) || ismissing(f)
        inter_ethnic[i] = missing
    elseif m == f
        inter_ethnic[i] = 0
    elseif m != f
        inter_ethnic[i] = 1
    end
end

census[!, :inter_ethnic] = inter_ethnic

# Interethnic marriage by ethnic group
inter_ethngrp = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.ethngrp_m[i]
    f = census.ethngrp_f[i]

    if ismissing(m) || ismissing(f)
        inter_ethngrp[i] = missing
    elseif m == f
        inter_ethngrp[i] = 0
    elseif m != f
        inter_ethngrp[i] = 1
    end
end

census[!, :inter_ethngrp] = inter_ethngrp

# Three types: intraethnic, intermarriage with Han, and intermarriage among minorities
# Ethnicity
inter_ethnic_type = Vector{Union{String,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.ethnicity_m[i]
    f = census.ethnicity_f[i]

    if ismissing(m) || ismissing(f)
        inter_ethnic_type[i] = missing
    elseif m == f
        inter_ethnic_type[i] = "Intra"
    elseif m != f && (m == "汉族" || f == "汉族")
        inter_ethnic_type[i] = "Inter_Han"
    elseif m != "汉族" && f != "汉族" && m != f
        inter_ethnic_type[i] = "Inter_minority"
    end
end

census[!, :inter_ethnic_type] = inter_ethnic_type

# Three types: intraethnic, intermarriage with Han, and intermarriage among minorities
# Ethnic group
inter_ethngrp_type = Vector{Union{String,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.ethngrp_m[i]
    f = census.ethngrp_f[i]

    if ismissing(m) || ismissing(f)
        inter_ethngrp_type[i] = missing
    elseif m == f
        inter_ethngrp_type[i] = "Intra"
    elseif m != f && (m == "Han" || f == "Han")
        inter_ethngrp_type[i] = "Inter_Han"
    elseif m != "Han" && f != "Han" && m != f
        inter_ethngrp_type[i] = "Inter_minority"
    end
end

census[!, :inter_ethngrp_type] = inter_ethngrp_type

# 2.2 Educational pairing -------------------------------------------------

edu_pair = Vector{Union{String,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.edu_m[i]
    f = census.edu_f[i]

    if ismissing(m) || ismissing(f)
        edu_pair[i] = missing
    elseif m == f
        edu_pair[i] = "homo"
    elseif m > f
        edu_pair[i] = "hyper"
    elseif m < f
        edu_pair[i] = "hypo"
    end
end

census[!, :edu_pair] = edu_pair

# 2.3 Ethnic entropy ------------------------------------------------------

# Calculate by year, province, and district
entropy_df = @chain census begin
    @groupby(:year, :province, :district)
    @combine(:ethn_entropy = calculate_entropy(:ethnicity))
end

# Merge back to main dataset
census = leftjoin!(census, entropy_df, on=[:year, :province, :district])

# 3 Save ------------------------------------------------------------------

Arrow.write("Data_cleaned/census.arrow", census)