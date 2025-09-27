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

# By gender
prop_women_by_ethngrp_year = @chain sample begin
    @groupby(:year, :ethngrp_f)
    @combine(:prop = mean(:inter_ethngrp))
    @rename(:ethngrp = :ethngrp_f)
    @transform(:sex = "female")
    @orderby(:year)
end

prop_men_by_ethngrp_year = @chain sample begin
    @groupby(:year, :ethngrp_m)
    @combine(:prop = mean(:inter_ethngrp))
    @rename(:ethngrp = :ethngrp_m)
    @transform(:sex = "male")
    @orderby(:year)
end

prop_by_ethngrp_year = vcat(prop_women_by_ethngrp_year, prop_men_by_ethngrp_year)

# Plot
f = Figure(; size=(1200, 800), fontsize=12)

inter_ethngrp_plt = data(prop_by_ethngrp_year) *
                    mapping(
                        :year => "",
                        :prop => "Proportion",
                        color=:sex => "Gender",
                        layout=:ethngrp
                    ) *
                    visual(ScatterLines)

plt = draw!(
    f[1, 1],
    inter_ethngrp_plt,
    scales(Color=(; palette=["#b3bfd1", "#b04238"])),
    axis=(;
        xticks=[1982, 1990, 2000, 2010],
        yticks=(0:0.2:0.8, ["0%", "20%", "40%", "60%", "80%"])
    )
)

legend!(f[1, 2], plt)

f

save("figures/trends_by_ethngrp.png", f; px_per_unit=2)

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

# Plot
f = Figure(; size=(1200, 800), fontsize=12)

inter_by_edu_plt = data(inter_by_edu_df) *
                   mapping(
                       :year => "",
                       :prop => "Proportion",
                       color=:edu => "Education",
                       dodge=:edu => "Education",
                       layout=:ethngrp
                   ) *
                   visual(BarPlot)

plt = draw!(
    f[1, 1],
    inter_by_edu_plt,
    scales(Color=(; palette=["#d7e1ee", "#a4a2a8", "#991f17"])),
    axis=(;
        yticks=(0:0.2:1, ["0%", "20%", "40%", "60%", "80%", "100%"]),
        limits = (nothing, (0, 1))
    )
)

legend!(f[1, 2], plt)

f

save("figures/trends_by_edu.png", f; px_per_unit=2)

# Full table by gender
inter_by_edu_gender_df = @chain df_long begin
    @groupby(:year, :ethngrp, :edu, :sex)
    @combine(:prop = mean(:inter_ethngrp) * 100)
    @transform(:prop = round.(:prop, digits=2))
    @orderby(:year, :ethngrp, :sex, :edu)
    println()
end
