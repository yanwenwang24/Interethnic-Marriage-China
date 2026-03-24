## ------------------------------------------------------------------------
##
## Purpose: Intermarriage trends by education level
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

df <- read_feather("data/visualization/fig2_trends_by_edu.arrow") |>
  mutate(
    ethngrp = factor(ethngrp, levels = ethngrp_order),
    edu = factor(edu, levels = edu_3_order),
    year = factor(year, levels = year_order)
  )

p <- ggplot(df, aes(x = year, y = prop, fill = edu)) +
  geom_col(
    position = position_dodge2(width = 0.8, preserve = "single"),
    width = 0.7
  ) +
  facet_wrap(~ ethngrp, nrow = 3) +
  scale_fill_manual(values = pal_edu_3, name = "Education") +
  scale_y_continuous(
    labels = percent_format(),
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2)
  ) +
  labs(x = NULL, y = "Proportion of Intermarriage") +
  theme_intermarriage()

ggsave("figures/trends_by_edu.pdf", p,
       width = 6.5, height = 6, device = cairo_pdf)

message("  Figure 2: trends_by_edu.pdf")
