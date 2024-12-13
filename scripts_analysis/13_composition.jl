## ------------------------------------------------------------------------
##
## Script name: 13_composition.jl
## Purpose: Compositions of ethnic groups and education
## Author: Yanwen Wang
## Date Created: 2024-10-07
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Ethnic composition ----------------------------------------------------

# Both genders
ethngrp_long = @chain sample begin
    @select(:year, :ethngrp_f, :ethngrp_m)
    stack([:ethngrp_f, :ethngrp_m], variable_name=:sex, value_name=:ethngrp)
end

ethngrp_comp = @chain ethngrp_long begin
    @groupby(:ethngrp)
    @combine(:prop = length(:ethngrp) / nrow(ethngrp_long) * 100)
    @orderby(-:prop)
    println()
end

# By gender
prop_ethngrp_female = prop(freqtable(sample, :year, :ethngrp_f), margins=1)
prop_ethngrp_male = prop(freqtable(sample, :year, :ethngrp_m), margins=1)

# 2 Education composition -------------------------------------------------

# 2.1 By year -------------------------------------------------------------

# By gender
prop_edu_female = prop(freqtable(sample, :year, :edu_f), margins=1)
prop_edu_male = prop(freqtable(sample, :year, :edu_m), margins=1)

# 2.2 By ethnic group -----------------------------------------------------

# Women
women_df = select(sample, :year, :ethngrp_f => :ethngrp, :edu_f => :edu)
women_df[!, :sex] .= "female"

# Men
men_df = select(sample, :year, :ethngrp_m => :ethngrp, :edu_m => :edu)
men_df[!, :sex] .= "male"

# Combine vertically
df_long = vcat(women_df, men_df)

# Proportion of each education by ethnic group
ethngrp_edu_comp = @chain df_long begin
    @groupby(:year, :ethngrp)
    @transform(:sum = length(:ethngrp))
    @groupby(:year, :ethngrp, :edu)
    @combine(:prop = length(:edu) / first(:sum))
    @orderby(-:year, :ethngrp, :edu)
end

ethngrp_edu_comp = @chain ethngrp_edu_comp begin
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

# Plot
f = Figure(; size=(1200, 800), fontsize=12)

ethngrp_edu_comp_plt = data(ethngrp_edu_comp) *
                       mapping(
                           :year => presorted => "",
                           :prop => "Proportion",
                           color=:edu => presorted => "Education",
                           stack=:edu => "Education",
                           row=:ethngrp
                       ) *
                       visual(BarPlot, direction=:x)

plt = draw!(
    f[1, 1],
    ethngrp_edu_comp_plt,
    scales(Color=(; palette=["#d7e1ee", "#a4a2a8", "#991f17"])),
    axis=(; xticks=(0:0.2:1, ["0%", "20%", "40%", "60%", "80%", "100%"]))
)

legend!(f[1, 2], plt)

f

save("graphs/edu_comp.png", f; px_per_unit=2)