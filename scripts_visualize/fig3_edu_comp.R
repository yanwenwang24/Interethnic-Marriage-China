## ------------------------------------------------------------------------
##
## Purpose: Education composition by ethnic group
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

df <- read_feather("data/visualization/fig3_edu_comp.arrow") |>
  mutate(
    ethngrp = factor(ethngrp, levels = rev(ethngrp_order)),
    edu = factor(edu, levels = edu_3_order),
    year = factor(year, levels = rev(year_order))
  )

p <- ggplot(df, aes(x = year, y = prop, fill = edu)) +
  geom_col(position = "stack", width = 0.7) +
  facet_grid(ethngrp ~ .) +
  coord_flip() +
  scale_fill_manual(values = pal_edu_3, name = "Education") +
  scale_y_continuous(
    labels = percent_format(),
    breaks = seq(0, 1, 0.2),
    expand = c(0, 0)
  ) +
  labs(x = NULL, y = "Proportion") +
  theme_intermarriage() +
  theme(
    strip.text.y.right = element_text(angle = 270, hjust = 0.5, margin = margin(l = 5)),
    panel.spacing.y = unit(0.3, "lines")
  )

ggsave("figures/edu_comp.pdf", p,
  width = 6.5, height = 9, device = cairo_pdf
)

message("  Figure 3: edu_comp.pdf")
