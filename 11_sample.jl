## ------------------------------------------------------------------------
##
## Script name: 11_sample.jl
## Purpose: Select samples for analysis
## Author: Yanwen Wang
## Date Created: 2024-10-06
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Select sample ---------------------------------------------------------

# Functions detailing sample selection rules
function sample_selection(female, age, marst, ethnicity, edu, ethnicity_sp, edu_sp)
    rule_sex = female == 1
    rule_age = !ismissing(age) && age >= 25 && age <= 34
    rule_marst = marst == "married"
    rule_ethnicity = !ismissing(ethnicity) && !ismissing(ethnicity_sp)
    rule_edu = !ismissing(edu) && !ismissing(edu_sp)

    return rule_sex && rule_age && rule_marst && rule_ethnicity && rule_edu
end

# Select samples based on the rules
sample = filter(
    [:female, :age, :marst, :ethnicity, :edu, :ethnicity_sp, :edu_sp] => sample_selection,
    census
)

@transform!(sample, :birthy_sp = :year - :age_sp)

# 2 Save sample -----------------------------------------------------------

Arrow.write("Data_cleaned/sample.arrow", sample)