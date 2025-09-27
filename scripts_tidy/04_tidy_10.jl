## ------------------------------------------------------------------------
##
## Purpose: Clean Census 2010 data
## Author: Yanwen Wang
## Date Created: 2024-10-05
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes: Census 2010 was in Chinese. Spousal location needs to be identified.
##
## ------------------------------------------------------------------------

# 1 Load data ---------------------------------------------------------------      

# Read dta file (original) and convert to arrow format
# using StatFiles, Arrow
# census_2010 = DataFrame(load("data/raw/2010_census.dta"))
# Arrow.write("data/raw/census_2010.arrow", census_2010)

# Read arrow file
census_2010 = DataFrame(Arrow.Table("data/raw/census_2010.arrow"))

# 2 Clean data --------------------------------------------------------------

# 2.1 Select variables of interest ------------------------------------------

census_2010 = @chain census_2010 begin
    @select(
        :地址码, :户编码,
        :当晚居住本户的人数,
        :与户主关系, :性别, :出生年, :婚姻状况, :结婚初婚年, :户口性质,
        :民族, :受教育程度
    )
    @rename(
        :hhnumber = :户编码,
        :persons = :当晚居住本户的人数,
        :relate = :与户主关系,
        :sex = :性别,
        :birthy = :出生年,
        :educcn = :受教育程度,
        :marst = :婚姻状况,
        :maryr = :结婚初婚年,
        :urban = :户口性质,
        :ethniccn = :民族
    )
    @transform(
        :year = 2010,
        :province = string.(parse.(Int, :地址码) .÷ 100000000000 .÷ 100),
        :district = lpad.(parse.(Int, :地址码) .÷ 100000000000 .% 100, 2, "0"),
        :hhsize = :persons
    )
    @transform(:region = get.(Ref(region_dict), :province, missing))
    @transform(:hhid = string.(:year, "_", :province, :district, :hhnumber))
    @transform(
        :minority = ifelse.(:ethniccn .== 1, 0, 1),
        :ethnicity = get.(Ref(ethn_dict), :ethniccn, missing),
        :ethngrp = get.(Ref(ethngrp_dict1), :ethniccn, missing)
    )
    @transform(:female = ifelse.(:sex .== 1, 0, 1))
    @transform(:age = :year - :birthy)
    @transform(:marst = get.(Ref(marst_dict), :marst, missing))
    @transform(:eduraw = get.(Ref(eduraw_2010_dict), :educcn, missing))
    @transform(:edu = get.(Ref(edu_2010_dict), :educcn, missing))
    @select(
        :year, :hhid, :region, :province, :district, :hhnumber,
        :relate, :female, :age, :birthy, :marst, :maryr, :urban, :hhsize,
        :eduraw, :edu,
        :ethnicity, :ethngrp, :minority
    )
end

# 2.2 Spousal information ----------------------------------------------------

# 2.2.1 Head location --------------------------------------------------------

# Add pernum
census_2010 = @chain census_2010 begin
    @groupby(:hhid)
    @transform(:pernum = 1:length(:hhid))
end

# Identify head location
headloc_df = @chain census_2010 begin
    @subset(:relate .== 0)
    @select(:hhid, :pernum)
    @rename(:headloc = :pernum)
end

census_2010 = leftjoin!(census_2010, headloc_df, on=:hhid)

# 2.2.2 Spouse location ------------------------------------------------------

# 2.2.2.1 Rule 1: head & spouse ----------------------------------------------

# Rule 1: head (`relate` == 0) and spouse (`relate` == 1)
# Extract heads
heads_df = @chain census_2010 begin
    @subset(:relate .== 0)
    @select(:hhid, :pernum)
    @rename(:head_pernum = :pernum)
end

# Extract spouses
spouses_df = @chain census_2010 begin
    @subset(:relate .== 1)
    @select(:hhid, :pernum)
    @rename(:sp_pernum = :pernum)
end

head_spouse_df = innerjoin(heads_df, spouses_df, on=:hhid)

# Prepare DataFrames for merging back
head_sploc_df = @chain head_spouse_df begin
    @rename(:pernum = :head_pernum, :sploc = :sp_pernum)
    # Remove duplicate `hhid` if multiple heads (keep first occurence)
    unique(:hhid)
end

spouse_sploc_df = @chain head_spouse_df begin
    @rename(:pernum = :sp_pernum, :sploc = :head_pernum)
    # Remove duplicate `hhid` if multiple spouses (keep first occurence)
    unique(:hhid)
end

sploc_df = vcat(head_sploc_df, spouse_sploc_df)

# Merge sploc back to main dataset
census_2010 = leftjoin(census_2010, sploc_df, on=[:hhid, :pernum])

# 2.2.2.2 Rule 2: parent & parent ---------------------------------------------

# Rule 2: parent (`relate` == 3) and parent (`relate` == 3)
# Extract parents
parents_df = @chain census_2010 begin
    @subset(:relate .== 3)
    @select(:hhid, :pernum)
end

# Self-join parents to find the other parent
parents_sploc_df = innerjoin(parents_df, parents_df, on=:hhid, makeunique=true)

# Exclude self matches
parents_sploc_df = @chain parents_sploc_df begin
    @subset(:pernum .!= :pernum_1)
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

# Handle multiple spouses by selecting the minimum `sploc`
parents_sploc_df = @chain parents_sploc_df begin
    @groupby(:hhid, :pernum)
    @combine(:sploc = minimum(:sploc))
end

# Merge sploc back to main dataset
census_2010 = leftjoin(census_2010, parents_sploc_df, on=[:hhid, :pernum], makeunique=true)
census_2010 = @transform(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
census_2010 = @select(census_2010, Not(:sploc_1))

# 2.2.2.3 Rule 3: parent-in-law & parent-in-law --------------------------------

# Rule 2: parent-in-law (`relate` == 4) and parent-in-law (`relate` == 4)
# Extract parents-in-law
parents_in_law_df = @chain census_2010 begin
    @subset(:relate .== 4)
    @select(:hhid, :pernum)
end

# Self-join parents-in-law to find the other parent-in-law
parents_in_law_sploc_df = innerjoin(parents_in_law_df, parents_in_law_df, on=:hhid, makeunique=true)

# Exclude self matches
parents_in_law_sploc_df = @chain parents_in_law_sploc_df begin
    @subset(:pernum .!= :pernum_1)
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

# Handle multiple spouses by selecting the minimum `sploc`
parents_in_law_sploc_df = @chain parents_in_law_sploc_df begin
    @groupby(:hhid, :pernum)
    @combine(:sploc = minimum(:sploc))
end

# Merge sploc back to main dataset
census_2010 = leftjoin(census_2010, parents_in_law_sploc_df, on=[:hhid, :pernum], makeunique=true)
census_2010 = @transform(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
census_2010 = @select(census_2010, Not(:sploc_1))

# 2.2.2.4 Rule 4: grandparent & grandparent -----------------------------------

# Rule 4: grandparent (`relate` == 5) and grandparent (`relate` == 5)
# Extract grandparents
grandparents_df = @chain census_2010 begin
    @subset(:relate .== 5)
    @select(:hhid, :pernum, :maryr)
end

# Count grandparents
grandparents_counts = @chain grandparents_df begin
    @groupby(:hhid)
    @combine(:n_grandparents = length(:pernum))
end

# Identify single-match households
single_match_hhids = @chain grandparents_counts begin
    @subset(:n_grandparents .== 2)
    @select(:hhid)
end

grandparents_single_df = semijoin(grandparents_df, single_match_hhids, on=:hhid)

# Self-join grandparents to find the other grandparent
grandparents_single_sploc_df = innerjoin(
    grandparents_single_df, grandparents_single_df,
    on=:hhid, makeunique=true
)

# Exclude self matches
grandparents_single_sploc_df = @chain grandparents_single_sploc_df begin
    @subset(:pernum .!= :pernum_1)
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

# Handle multiple spouses by selecting the minimum `sploc`
grandparents_single_sploc_df = @chain grandparents_single_sploc_df begin
    @groupby(:hhid, :pernum)
    @combine(:sploc = minimum(:sploc))
end

# Identify multiple-match households
multiple_match_hhids = @chain grandparents_counts begin
    @subset(:n_grandparents .> 2)
    @select(:hhid)
end

# Match grandparents in multiple-match households by `maryr`
grandparents_multiple_df = semijoin(grandparents_df, multiple_match_hhids, on=:hhid)

# Group by `hhid` and `maryr`
grouped_df = groupby(grandparents_multiple_df, [:hhid, :maryr])

# Apply function create_matches() to each group
sploc_rule4_multiple_df = combine(grouped_df, create_parent_matches)
sploc_rule4_multiple_df = select(sploc_rule4_multiple_df, [:hhid, :pernum, :sploc])

# Combine and merge sploc back to main dataset
sploc_rule4_df = vcat(grandparents_single_sploc_df, sploc_rule4_multiple_df)

# Merge sploc back to main dataset
census_2010 = leftjoin(census_2010, sploc_rule4_df, on=[:hhid, :pernum], makeunique=true)
census_2010 = @transform(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
census_2010 = @select(census_2010, Not(:sploc_1))

# 2.2.2.5 Rule 5: children & children-in-law ----------------------------------

# Rule 5: children (`relate` == 2) and children-in-law (`relate` == 6)
# Extract married children
children_df = @chain census_2010 begin
    @subset(:relate .== 2, :marst .== "married")
    @select(:hhid, :pernum, :maryr)
end

# Extract married children-in-law
children_in_law_df = @chain census_2010 begin
    @subset(:relate .== 6, :marst .== "married")
    @select(:hhid, :pernum, :maryr)
end

# Count married children
children_counts = @chain children_df begin
    @groupby(:hhid)
    @combine(:n_children = length(:pernum))
end

# Count married children-in-law
children_in_law_counts = @chain children_in_law_df begin
    @groupby(:hhid)
    @combine(:n_children_in_law = length(:pernum))
end

counts = leftjoin(children_counts, children_in_law_counts, on=:hhid)

# Identify single-match households
single_match_hhids = @chain counts begin
    @subset(:n_children .== 1, :n_children_in_law .== 1)
    @select(:hhid)
end

# Married children and children-in-law in single-match households
children_single_df = semijoin(children_df, single_match_hhids, on=:hhid)
children_in_law_single_df = semijoin(children_in_law_df, single_match_hhids, on=:hhid)

single_matches_df = innerjoin(children_single_df, children_in_law_single_df, on=:hhid, makeunique=true)

# Assign `sploc` for children and children-in-law
child_single_sploc_df = @chain single_matches_df begin
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

children_in_law_single_sploc_df = @chain single_matches_df begin
    @select(:hhid, :pernum_1, :pernum)
    @rename(
        :pernum = :pernum_1,
        :sploc = :pernum
    )
end

sploc_rule5_single_df = vcat(child_single_sploc_df, children_in_law_single_sploc_df)

# Identify multiple-match households
# At least one married child and at least one married child-in-law, excluding single-match households
# Collect `pernum` of married children and children-in-law.
# Sort the `pernum` to maintain a consistent order.
# Pair the married children with married children-in-law in order, up to the number of available matches.
# Assign the sploc accordingly, ensuring one-to-one matching.
multiple_match_hhids = @chain counts begin
    @subset(:n_children .>= 1, :n_children_in_law .>= 1, :n_children .+ :n_children_in_law .> 2)
    @select(:hhid)
end

# Children and children-in-law in multiple-match households
children_multiple_df = semijoin(children_df, multiple_match_hhids, on=:hhid)
children_in_law_multiple_df = semijoin(children_in_law_df, multiple_match_hhids, on=:hhid)

# Add a column to indicate role
children_multiple_df = @transform(children_multiple_df, :role = "child")
children_in_law_multiple_df = @transform(children_in_law_multiple_df, :role = "child_in_law")

# Combine children and children-in-law
combined_df = vcat(children_multiple_df, children_in_law_multiple_df)

# Group by `hhid` and `maryr`
grouped_df = groupby(combined_df, [:hhid, :maryr])

# Apply function create_matches() to each group
sploc_rule5_multiple_df = combine(grouped_df, create_children_matches)
sploc_rule5_multiple_df = select(sploc_rule5_multiple_df, [:hhid, :pernum, :sploc])

# Combine and merge sploc back to main dataset
sploc_rule5_df = vcat(sploc_rule5_single_df, sploc_rule5_multiple_df)

census_2010 = leftjoin(census_2010, sploc_rule5_df, on=[:hhid, :pernum], makeunique=true)
census_2010 = @transform(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
census_2010 = @select(census_2010, Not(:sploc_1))

# Fill missing sploc with 0
census_2010 = @transform(census_2010, :sploc = coalesce.(:sploc, 0))

# 2.2.3 Spousal information --------------------------------------------------

# Information needed for spouse
df = @select(census_2010,
    :hhid, :pernum, :relate, :maryr, :sploc,
    :ethnicity, :ethngrp, :minority,
    :eduraw, :edu,
    :age, :female, :urban
)

# Identify spousal information using `pernum` to `sploc` linkage
sp_df = leftjoin(
    df, df,
    on=[:hhid => :hhid, :pernum => :sploc],
    renamecols="" => "_sp"
)

sp_df = @select(
    sp_df,
    :hhid, :pernum, :ethnicity_sp, :ethngrp_sp, :minority_sp,
    :eduraw_sp, :edu_sp, :age_sp, :urban_sp
)

# Merge spousal information back to main dataset
census_2010 = leftjoin(census_2010, sp_df, on=[:hhid, :pernum])

# Identiy male and female information
census_2010 = @chain census_2010 begin
    @transform(
        :ethnicity_m = ifelse.(:female .== 0, :ethnicity, :ethnicity_sp),
        :ethnicity_f = ifelse.(:female .== 0, :ethnicity_sp, :ethnicity),
        :ethngrp_m = ifelse.(:female .== 0, :ethngrp, :ethngrp_sp),
        :ethngrp_f = ifelse.(:female .== 0, :ethngrp_sp, :ethngrp),
        :minority_m = ifelse.(:female .== 0, :minority, :minority_sp),
        :minority_f = ifelse.(:female .== 0, :minority_sp, :minority),
        :eduraw_m = ifelse.(:female .== 0, :eduraw, :eduraw_sp),
        :eduraw_f = ifelse.(:female .== 0, :eduraw_sp, :eduraw),
        :edu_m = ifelse.(:female .== 0, :edu, :edu_sp),
        :edu_f = ifelse.(:female .== 0, :edu_sp, :edu),
        :age_m = ifelse.(:female .== 0, :age, :age_sp),
        :age_f = ifelse.(:female .== 0, :age_sp, :age),
        :urban_m = ifelse.(:female .== 0, :urban, :urban_sp),
        :urban_f = ifelse.(:female .== 0, :urban_sp, :urban)
    )
    @select(Not(:maryr))
end

# 3 Save data ---------------------------------------------------------------

Arrow.write("Data_cleaned/census_2010.arrow", census_2010)