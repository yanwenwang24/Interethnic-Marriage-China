## ------------------------------------------------------------------------
##
## Purpose: Describe interethnic marriage patterns and trends
## Author: Yanwen Wang
## Date Created: 2024-10-06
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Overall trends --------------------------------------------------------

prop_df = prop(freqtable(sample, :inter_ethngrp_type, :year), margins=2)

# 2 By ethnic group -------------------------------------------------------

# Both genders
prop_by_ethngrp_year = @chain sample begin
    @select(:year, :ethngrp_f, :ethngrp_m, :inter_ethngrp)
    # stack into long format
    stack([:ethngrp_f, :ethngrp_m], variable_name=:gender, value_name=:ethngrp)
    @groupby(:year, :ethngrp)
    @combine(:prop = mean(:inter_ethngrp))
    @orderby(-:prop)
end

Arrow.write("data/visualization/fig1_trends_by_ethngrp.arrow", prop_by_ethngrp_year)

# 3 By Education ----------------------------------------------------------

# Women
women_df = select(sample, :year, :ethngrp_f => :ethngrp, :edu_f => :edu, :inter_ethngrp)
women_df[!, :sex] .= "female"

# Men
men_df = select(sample, :year, :ethngrp_m => :ethngrp, :edu_m => :edu, :inter_ethngrp)
men_df[!, :sex] .= "male"

# Combine vertically
df_long = vcat(women_df, men_df)

# Intermarriage rates by education
inter_by_edu_df = @chain df_long begin
    @groupby(:year, :ethngrp, :edu)
    @combine(:prop = mean(:inter_ethngrp))
    @orderby(:year, :ethngrp, :edu)
end

inter_by_edu_df = @chain inter_by_edu_df begin
    @transform(
        :edu = replace(:edu,
            1 => "Low",
            2 => "Middle",
            3 => "High"
        )
    )
    @transform(:edu = categorical(:edu, levels=["Low", "Middle", "High"]))
    @transform(:year = categorical(:year))
end

Arrow.write("data/visualization/fig2_trends_by_edu.arrow", inter_by_edu_df)

# Full table by gender
inter_by_edu_gender_df = @chain df_long begin
    @groupby(:year, :ethngrp, :edu, :sex)
    @combine(:prop = mean(:inter_ethngrp) * 100)
    @transform(:prop = round.(:prop, digits=2))
    @orderby(:year, :ethngrp, :sex, :edu)
    println()
end
