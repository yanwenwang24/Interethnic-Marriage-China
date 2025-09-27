## ------------------------------------------------------------------------
##
## Script name: 02_tidy_90.jl
## Purpose: Clean Census 1990 data
## Author: Yanwen Wang
## Date Created: 2024-10-05
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes: Census 1990 was downloaded from IPUMS International.
##
## ------------------------------------------------------------------------

# 1 Load data ---------------------------------------------------------------      

# Read dta file (original) and convert to arrow format
# using StatFiles, Arrow
# census_1990 = DataFrame(load("Data_original/1990_census.dta"))
# Arrow.write("Data_original/census_1990.arrow", census_1990)

# Read arrow file
census_1990 = DataFrame(Arrow.Table("Data_original/census_1990.arrow"))

# 2 Clean data --------------------------------------------------------------

# 2.1 Select variables of interest ------------------------------------------

census_1990 = @chain census_1990 begin
    @select(
        :year, :geo1_cn, :geo2_cn, :serial,
        :persons, :headloc, :pernum, :sploc,
        :relate, :sex, :age, :marst, :ethniccn,
        :educcn
    )
    @transform(
        :province = lpad.(:geo1_cn .% 156000, 2, "0"),
        :district = lpad.(:geo2_cn .% (:geo1_cn .* 1000), 2, "0"),
        :hhnumber = lpad.(Int.(:serial), 10, "0"),
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
    @transform(:birthy = :year - :age)
    @transform(:marst = get.(Ref(marst_dict), :marst, missing))
    @transform(
        :eduraw = eduraw_map[:educcn.+1],
        :edu = edu_map[:educcn.+1]
    )
    @transform(:urban = 999) # missing urban status
    @select(
        :year, :hhid, :region, :province, :district, :hhnumber,
        :pernum, :headloc, :sploc,
        :relate, :female, :age, :birthy, :marst, :urban, :hhsize,
        :eduraw, :edu,
        :ethnicity, :ethngrp, :minority
    )
end

# 2.2 Spousal information ----------------------------------------------------

# Information needed for spouse
df = @select(census_1990,
    :hhid, :pernum, :sploc,
    :ethnicity, :ethngrp, :minority,
    :eduraw, :edu,
    :age, :female, :urban
)

# Identify spousal information using `pernum` to `sploc` linkage
sp_df = leftjoin(df, df, on=[:hhid => :hhid, :pernum => :sploc], renamecols="" => "_sp")
sp_df = @select(
    sp_df,
    :hhid, :pernum, :ethnicity_sp, :ethngrp_sp, :minority_sp,
    :eduraw_sp, :edu_sp, :age_sp, :urban_sp
)

# Merge spousal information back to main dataset
census_1990 = leftjoin(census_1990, sp_df, on=[:hhid, :pernum])

# Identiy male and female information
census_1990 = @chain census_1990 begin
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
end

# 3 Save data ---------------------------------------------------------------

Arrow.write("Data_cleaned/census_1990.arrow", census_1990)